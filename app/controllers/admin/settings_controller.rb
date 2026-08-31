module Admin
  class SettingsController < BaseController
    before_action :require_admin!
    def edit
      @webhook_url  = AppSetting.get(:webhook_url).to_s
      @webhook_auth = AppSetting.get(:webhook_auth).to_s
      @lab_name     = AppSetting.get(:lab_name) || ENV.fetch('LAB_NAME', 'Check-in Expresso')
    end

    def update
      AppSetting.set(:webhook_url,  params[:webhook_url].to_s.strip)
      AppSetting.set(:webhook_auth, params[:webhook_auth].to_s.strip)
      AppSetting.set(:lab_name,     params[:lab_name].to_s.strip) if params[:lab_name].present?

      redirect_to edit_admin_settings_path, notice: "Configurações salvas com sucesso!"
    end
  end
end
