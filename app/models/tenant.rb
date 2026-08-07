class Tenant < ApplicationRecord
  has_many :units, dependent: :destroy
  has_many :walk_ins, dependent: :destroy
  has_many :users, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9\-]+\z/, message: "apenas letras minúsculas, números e hífens" }

  scope :active, -> { where(active: true) }
end
