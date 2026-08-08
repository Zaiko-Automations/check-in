module Admin
  class DashboardController < BaseController
    def index
      @status = params[:status] || 'pending'
      
      # Permission scoping: attendants only see walk-ins for their unit
      scope = WalkIn.all
      if current_user.unit_id.present?
        scope = scope.where(unit_id: current_user.unit_id)
      end

      # For 'pending' tab, show both 'pending' and 'failed' webhooks
      query_status = @status == 'pending' ? ['pending', 'failed'] : @status

      @walk_ins = scope.includes(:patient, :unit)
                       .where(status: query_status)
                       .order(created_at: :desc)

      # Search filter
      if params[:search].present?
        search_term = "%#{params[:search].strip}%"
        @walk_ins = @walk_ins.joins(:patient)
                             .where("patients.nome ILIKE :search OR patients.cpf ILIKE :search OR walk_ins.uid ILIKE :search", search: search_term)
      end

      @walk_ins = @walk_ins.limit(100)

      # Counts scoped by the same unit permissions
      @counts = {
        pending:      scope.where(status: ['pending', 'failed']).count,
        webhook_sent: scope.webhook_sent.count,
        completed:    scope.completed.count,
        today:        scope.today.count
      }
    end
  end
end
