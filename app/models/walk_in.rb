class WalkIn < ApplicationRecord
  belongs_to :unit
  has_one :patient, dependent: :destroy
  has_many :requested_exams, dependent: :destroy
  accepts_nested_attributes_for :patient
  accepts_nested_attributes_for :requested_exams, allow_destroy: true

  # Images stored in Cloudflare R2 / Disk
  has_one_attached :foto_senha
  has_one_attached :carteira_convenio
  has_many_attached :requisicoes_medicas
  has_one_attached :documento

  PRIORIDADES = {
    'geral'            => 'Geral',
    'preferencial'     => 'Preferencial (60+, Gestante, PCD)',
    'superprioridade'  => 'Superprioridade (80+ anos)'
  }.freeze

  ORIGENS = {
    'qrcode' => 'Presencial (QR Code)',
    'link'   => 'Remoto (Link / Em Casa)'
  }.freeze

  before_create :generate_uid

  enum status: {
    pending:      'pending',
    webhook_sent: 'webhook_sent',
    completed:    'completed',
    failed:       'failed'
  }, _default: 'pending'

  scope :today,   -> { where(created_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }
  scope :recent,  -> { order(created_at: :desc) }
  scope :pending,      -> { where(status: 'pending') }
  scope :webhook_sent, -> { where(status: 'webhook_sent') }
  scope :completed,    -> { where(status: 'completed') }

  def foto_senha_url
    return nil unless foto_senha.attached?
    Rails.application.routes.url_helpers.rails_blob_url(foto_senha, host: app_host)
  end

  def carteira_convenio_url
    return nil unless carteira_convenio.attached?
    Rails.application.routes.url_helpers.rails_blob_url(carteira_convenio, host: app_host)
  end

  def requisicoes_medicas_urls
    return [] unless requisicoes_medicas.attached?
    requisicoes_medicas.map do |pm|
      Rails.application.routes.url_helpers.rails_blob_url(pm, host: app_host)
    end
  end

  def documento_url
    return nil unless documento.attached?
    Rails.application.routes.url_helpers.rails_blob_url(documento, host: app_host)
  end

  def prioridade_label
    PRIORIDADES[prioridade] || prioridade.to_s.humanize
  end

  def origem_label
    ORIGENS[origem] || origem.to_s.humanize
  end

  private

  def generate_uid
    date_part   = Time.current.strftime('%Y%m%d')
    random_part = SecureRandom.alphanumeric(6).upcase
    self.uid    = "WLK-#{date_part}-#{random_part}"
  end

  def app_host
    ENV.fetch('APP_HOST', 'check-in.zaikohub.com.br')
  end
end
