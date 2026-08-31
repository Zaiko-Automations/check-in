module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!

    layout 'admin'

    private

    # Restrict an action to admins only. Call from individual controllers.
    def require_admin!
      unless current_user&.admin?
        redirect_to admin_root_path, alert: "Acesso negado. Apenas administradores podem realizar esta ação."
      end
    end
  end
end
