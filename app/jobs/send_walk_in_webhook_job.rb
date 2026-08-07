class SendWalkInWebhookJob < ApplicationJob
  queue_as :default

  WEBHOOK_URL = 'https://auto.zaikohub.com.br/webhook/walk-in-333'.freeze
  WEBHOOK_TOKEN = 'EAAm8baDUqp4BQ2MvMkpkTKO8wVWMeKrCz9fmCCZAmq8CWQ2dbUtAW4wIf9Yh'.freeze

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(walk_in_id)
    walk_in = WalkIn.find(walk_in_id)
    patient = walk_in.patient
    unit    = walk_in.unit
    tenant  = walk_in.tenant

    payload = build_payload(walk_in, patient, unit, tenant)

    response = Net::HTTP.post(
      URI(WEBHOOK_URL),
      payload.to_json,
      'Content-Type'  => 'application/json',
      'Authorization' => WEBHOOK_TOKEN
    )

    if response.is_a?(Net::HTTPSuccess)
      walk_in.update!(status: 'webhook_sent', webhook_sent_at: Time.current)
      Rails.logger.info "[WalkIn Webhook] ✅ Sent walk_in ##{walk_in.uid} — HTTP #{response.code}"
    else
      walk_in.update!(status: 'failed', webhook_error: "HTTP #{response.code}: #{response.body.truncate(300)}")
      Rails.logger.error "[WalkIn Webhook] ❌ Failed walk_in ##{walk_in.uid} — HTTP #{response.code}: #{response.body}"
      raise "Webhook failed with HTTP #{response.code}"
    end
  end

  private

  def build_payload(walk_in, patient, unit, tenant)
    cobertura = if patient.convenio?
      {
        tipo:             'convenio',
        convenio:         patient.convenio,
        plano:            patient.plano.presence,
        numero_carteira:  patient.numero_carteira.presence,
        validade_carteira: patient.validade_carteira&.strftime('%Y-%m-%d')
      }
    else
      { tipo: 'particular' }
    end

    {
      event:      'walk_in.submitted',
      walk_in_id: walk_in.uid,
      submitted_at: walk_in.created_at.iso8601,

      tenant: {
        subdomain: tenant.subdomain,
        name:      tenant.name
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

      documents: {
        carteira_convenio: walk_in.carteira_convenio_url,
        requisicao_medica: walk_in.requisicao_medica_url
      }
    }
  end
end
