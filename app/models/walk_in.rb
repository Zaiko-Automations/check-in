class WalkIn < ApplicationRecord
  belongs_to :tenant
  belongs_to :unit
  has_one :patient, dependent: :destroy

  acts_as_tenant :tenant

  # Images stored in cloud, generating public URLs
  has_one_attached :carteira_convenio
  has_one_attached :requisicao_medica

  before_create :generate_uid

  enum status: {
    pending:      'pending',
    webhook_sent: 'webhook_sent',
    completed:    'completed',
    failed:       'failed'
  }, _default: 'pending'

  scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :recent, -> { order(created_at: :desc) }

  # Returns the public URL of an attached image (for the n8n payload)
  def carteira_convenio_url
    return nil unless carteira_convenio.attached?
    Rails.application.routes.url_helpers.rails_blob_url(carteira_convenio, host: app_host)
  end

  def requisicao_medica_url
    return nil unless requisicao_medica.attached?
    Rails.application.routes.url_helpers.rails_blob_url(requisicao_medica, host: app_host)
  end

  private

  def generate_uid
    date_part = Time.current.strftime('%Y%m%d')
    random_part = SecureRandom.alphanumeric(6).upcase
    self.uid = "WLK-#{date_part}-#{random_part}"
  end

  def app_host
    ENV.fetch('APP_HOST', 'labwalkin.zaikohub.com.br')
  end
end
