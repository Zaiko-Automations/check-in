class Unit < ApplicationRecord
  has_many :walk_ins, dependent: :destroy

  before_validation :generate_token, on: :create

  validates :name,  presence: true
  validates :token, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def checkin_url(host: nil, origem: 'link')
    base = host || ENV.fetch('APP_HOST', 'check-in.zaikohub.com.br')
    "https://#{base}/checkin/#{token}?origem=#{origem}"
  end

  def qr_url(host: nil)
    checkin_url(host: host, origem: 'qrcode')
  end

  def link_url(host: nil)
    checkin_url(host: host, origem: 'link')
  end

  def qr_svg
    qr = RQRCode::QRCode.new(qr_url)
    qr.as_svg(
      offset:           0,
      color:            "000",
      shape_rendering:  "crispEdges",
      module_size:      6,
      standalone:       true
    )
  end

  private

  def generate_token
    self.token = loop do
      t = SecureRandom.urlsafe_base64(12)
      break t unless Unit.exists?(token: t)
    end
  end
end
