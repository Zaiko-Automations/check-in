class Unit < ApplicationRecord
  belongs_to :tenant
  has_many :walk_ins, dependent: :destroy

  acts_as_tenant :tenant

  before_validation :generate_token, on: :create

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }

  def checkin_url(host: nil)
    base = host || "#{tenant.subdomain}.labwalkin.zaikohub.com.br"
    "https://#{base}/checkin/#{token}"
  end

  def qr_svg
    qr = RQRCode::QRCode.new(checkin_url)
    qr.as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true
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
