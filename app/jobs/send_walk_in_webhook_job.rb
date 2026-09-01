require 'net/http'

class SendWalkInWebhookJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(walk_in_id, webhook_type = 'final')
    walk_in = WalkIn.find(walk_in_id)
    patient = walk_in.patient
    unit    = walk_in.unit

    if webhook_type == 'extraction'
      # Extraction webhook goes to default zaikohub webhook URL
      webhook_url  = ENV['DEFAULT_WEBHOOK_URL'].presence || 'https://auto.zaikohub.com.br/webhook/check-in-expresso'
      webhook_auth = ENV['DEFAULT_WEBHOOK_AUTH'].presence
    else
      # Final webhook goes to customer's custom setting URL
      webhook_url  = AppSetting.webhook_url
      webhook_auth = AppSetting.webhook_auth

      unless webhook_url.present?
        Rails.logger.info "[WalkIn Webhook] ⚠️  Webhook Final não configurado — pulando envio."
        return
      end
    end

    payload = build_payload(walk_in, patient, unit, webhook_type)

    headers = { 'Content-Type' => 'application/json' }
    headers['Authorization'] = webhook_auth if webhook_auth.present?

    response = Net::HTTP.post(
      URI(webhook_url),
      payload.to_json,
      headers
    )

    if response.is_a?(Net::HTTPSuccess)
      new_status = webhook_type == 'extraction' ? 'webhook_sent' : 'completed'
      walk_in.update!(status: new_status, webhook_sent_at: Time.current)
      Rails.logger.info "[WalkIn Webhook] ✅ Enviado (#{webhook_type}) walk_in ##{walk_in.uid} — HTTP #{response.code}"
    else
      if webhook_type == 'extraction'
        # Extraction failure updates status to failed so it shows on dashboard
        walk_in.update!(status: 'failed', webhook_error: "HTTP #{response.code}: #{response.body.truncate(300)}")
      end
      Rails.logger.error "[WalkIn Webhook] ❌ Falha (#{webhook_type}) walk_in ##{walk_in.uid} — HTTP #{response.code}: #{response.body}"
      raise "Webhook falhou com HTTP #{response.code}"
    end
  end

  private

  def build_payload(walk_in, patient, unit, webhook_type)
    lab_name = AppSetting.get(:lab_name) || ENV.fetch('LAB_NAME', 'Check-in Expresso')

    cobertura = if patient.cobertura_tipo == 'convenio'
      {
        tipo:              'convenio',
        convenio:          patient.convenio,
        plano:             patient.plano.presence,
        numero_carteira:   patient.numero_carteira.presence,
        validade_carteira: patient.validade_carteira&.strftime('%Y-%m-%d')
      }
    else
      { tipo: 'particular' }
    end

    {
      event:        webhook_type == 'extraction' ? 'walk_in.submitted' : 'walk_in.validated',
      walk_in_id:   walk_in.uid,
      id:           walk_in.id,
      submitted_at: walk_in.created_at.iso8601,
      origem:       walk_in.origem,
      prioridade:   walk_in.prioridade,
      numero_senha: walk_in.numero_senha,

      laboratorio: {
        nome: lab_name,
        host: ENV.fetch('APP_HOST', 'check-in.zaikohub.com.br')
      },

      unit: {
        id:   unit.id,
        name: unit.name,
        city: unit.city.presence
      },

      patient: {
        nome:               patient.nome,
        cpf:                patient.cpf,
        data_nascimento:    patient.data_nascimento&.strftime('%Y-%m-%d'),
        sexo_biologico:     patient.sexo_biologico,
        telefone:           patient.telefone,
        whatsapp:           patient.whatsapp,
        cidade_atendimento: patient.cidade_atendimento,
        logradouro:         patient.logradouro,
        numero:             patient.numero,
        bairro:             patient.bairro,
        cidade:             patient.cidade,
        uf:                 patient.uf,
        cep:                patient.cep,
        complemento:        patient.complemento
      },

      cobertura: cobertura,

      solicitante: {
        nome:               walk_in.respond_to?(:solicitante_nome) ? walk_in.solicitante_nome : nil,
        conselho:           walk_in.respond_to?(:solicitante_conselho) ? walk_in.solicitante_conselho : nil,
        especialidade:      walk_in.respond_to?(:solicitante_especialidade) ? walk_in.solicitante_especialidade : nil,
        data_pedido_medico: walk_in.respond_to?(:data_pedido_medico) ? walk_in.data_pedido_medico&.strftime('%Y-%m-%d') : nil
      },

      exams: walk_in.requested_exams.map { |e| { codigo: e.codigo, descricao: e.descricao, acuracia: e.acuracia } },

      documents: {
        foto_senha:          walk_in.foto_senha_url,
        carteira_convenio:   walk_in.carteira_convenio_url,
        requisicoes_medicas: walk_in.requisicoes_medicas_urls,
        documento:           walk_in.documento_url
      }
    }
  end
end
