class User < ApplicationRecord
  belongs_to :unit, optional: true

  # Roles: 'admin' can manage everything, 'attendant' can only view/process walk-ins
  enum role: { admin: 'admin', attendant: 'attendant' }, _default: 'attendant'

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Guard: attendants cannot be assigned no unit (optional) but admins always have full access
  def admin?
    role == 'admin'
  end

  def attendant?
    role == 'attendant'
  end

  def display_role
    admin? ? 'Administrador' : 'Atendente'
  end
end
