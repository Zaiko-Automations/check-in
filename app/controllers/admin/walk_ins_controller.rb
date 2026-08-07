module Admin
  class WalkInsController < BaseController
    before_action :set_walk_in, only: [:show, :complete]

    def show
      @patient = @walk_in.patient
    end

    def complete
      # Endpoint para a recepcionista marcar o atendimento como concluído
      if @walk_in.update(status: 'completed')
        redirect_to admin_root_path, notice: "Atendimento concluído com sucesso."
      else
        redirect_to admin_walk_in_path(@walk_in), alert: "Erro ao concluir atendimento."
      end
    end

    private

    def set_walk_in
      @walk_in = current_tenant.walk_ins.find(params[:id])
    end
  end
end
