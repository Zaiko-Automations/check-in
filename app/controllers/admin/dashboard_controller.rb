module Admin
  class DashboardController < BaseController
    def index
      @status   = params[:status] || 'pending'
      @walk_ins = WalkIn.includes(:patient, :unit)
                        .where(status: @status)
                        .order(created_at: :desc)
                        .limit(100)

      @counts = {
        pending:      WalkIn.pending.count,
        webhook_sent: WalkIn.webhook_sent.count,
        completed:    WalkIn.completed.count,
        today:        WalkIn.today.count
      }
    end
  end
end
