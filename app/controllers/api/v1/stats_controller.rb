module Api
  module V1
    class StatsController < ActionController::Base
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
    end
  end
end
