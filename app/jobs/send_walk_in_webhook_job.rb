require 'net/http'

class SendWalkInWebhookJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(walk_in_id)
    # Read webhook config from DB (set via Admin > Configurações)
    webhook_url  = AppSetting.webhook_url
    webhook_auth = AppSetting.webhook_auth

    unless webhook_url.present?
      Rails.logger.info "[WalkIn Webhook] ⚠️  Webhook URL não configurada — pulando envio."
      return
    end

    walk_in = WalkIn.find(walk_in_id)
    patient = walk_in.patient
    unit    = walk_in.unit

    payload = build_payload(walk_in, patient, unit)

    headers = { 'Content-Type' => 'application/json' }
    headers['Authorization'] = webhook_auth if webhook_auth.present?

    response = Net::HTTP.post(
      URI(webhook_url),
      payload.to_json,
      headers
    )

    if response.is_a?(Net::HTTPSuccess)
      walk_in.update!(status: 'webhook_sent', webhook_sent_at: Time.current)
      Rails.logger.info "[WalkIn Webhook] ✅ Enviado walk_in ##{walk_in.uid} — HTTP #{response.code}"
    else
      walk_in.update!(status: 'failed', webhook_error: "HTTP #{response.code}: #{response.body.truncate(300)}")
      Rails.logger.error "[WalkIn Webhook] ❌ Falha walk_in ##{walk_in.uid} — HTTP #{response.code}: #{response.body}"
      raise "Webhook falhou com HTTP #{response.code}"
    end
  end

  private

  def build_payload(walk_in, patient, unit)
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
      event:        'walk_in.submitted',
      walk_in_id:   walk_in.uid,
      submitted_at: walk_in.created_at.iso8601,

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
        nome:            patient.nome,
        cpf:             patient.cpf,
        data_nascimento: patient.data_nascimento&.strftime('%Y-%m-%d'),
        sexo_biologico:  patient.sexo_biologico,
        telefone:        patient.telefone,
        whatsapp:        patient.whatsapp
      },

      cobertura: cobertura,

      exams: walk_in.requested_exams.map { |e| { codigo: e.codigo, descricao: e.descricao, acuracia: e.acuracia } },

      documents: {
        carteira_convenio: walk_in.carteira_convenio_url,
        requisicao_medica: walk_in.requisicao_medica_url,
        documento:         walk_in.documento_url
      }
    }
  end
end
