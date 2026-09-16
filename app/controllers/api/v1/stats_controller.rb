module Api
  module V1
    class StatsController < ActionController::API
      before_action :authenticate_token!

      def show
        today     = Time.current.beginning_of_day..Time.current.end_of_day
        this_month = Time.current.beginning_of_month..Time.current.end_of_month

        render json: {
          lab_name:            AppSetting.get(:lab_name) || ENV.fetch('LAB_NAME', 'Check-in Expresso'),
          host:                ENV.fetch('APP_HOST', request.host),
          atendimentos_hoje:   WalkIn.where(created_at: today).count,
          atendimentos_mes:    WalkIn.where(created_at: this_month).count,
          atendimentos_total:  WalkIn.count,
          pendentes_agora:     WalkIn.pending.count
        }
      end

      private

      def authenticate_token!
        token = request.headers['X-API-Token'] ||
                request.headers['Authorization']&.split(' ')&.last

        expected_token = ENV['WEBHOOK_API_TOKEN']
        if expected_token.blank?
          render json: { error: 'Server misconfiguration' }, status: :internal_server_error
          return
        end

        if token.blank? || !ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    end
  end
end
