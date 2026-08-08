class AppSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  # Convenience methods
  def self.get(key)
    find_by(key: key.to_s)&.value
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key.to_s)
    setting.value = value
    setting.save!
  end

  # Webhook shortcuts
  def self.webhook_url
    get(:webhook_url)
  end

  def self.webhook_auth
    get(:webhook_auth)
  end
end
