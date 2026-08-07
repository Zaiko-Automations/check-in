class ApplicationController < ActionController::Base
  before_action :set_tenant_from_subdomain

  private

  def set_tenant_from_subdomain
    subdomain = request.subdomain.presence

    # In development, allow ?tenant= param for testing without real subdomains
    if Rails.env.development? && params[:tenant].present?
      subdomain = params[:tenant]
    end

    if subdomain.present? && subdomain != 'www'
      @current_tenant = Tenant.find_by(subdomain: subdomain, active: true)
      if @current_tenant
        ActsAsTenant.current_tenant = @current_tenant
      else
        render plain: "Laboratório não encontrado.", status: :not_found
      end
    end
  end

  def current_tenant
    @current_tenant
  end
  helper_method :current_tenant
end
