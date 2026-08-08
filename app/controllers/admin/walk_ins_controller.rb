module Admin
  class WalkInsController < BaseController
    before_action :set_walk_in, only: [:show, :update, :complete, :destroy]

    def show
      @patient = @walk_in.patient
    end

    def update
      @patient = @walk_in.patient
      
      ActiveRecord::Base.transaction do
        if @walk_in.update(walk_in_params)
          if params[:commit] == 'Salvar'
            redirect_to admin_walk_in_path(@walk_in), notice: "Alterações salvas com sucesso."
          else
            # "Validar" / "Enviar"
            @walk_in.update!(status: 'completed')
            # Trigger webhook callback if configured
            SendWalkInWebhookJob.perform_later(@walk_in.id)
            redirect_to admin_root_path, notice: "Check-in de #{@patient.nome} validado e concluído!"
          end
        else
          flash.now[:alert] = "Não foi possível salvar as alterações: #{@walk_in.errors.full_messages.to_sentence}"
          render :show, status: :unprocessable_entity
        end
      end
    end

    def complete
      if @walk_in.update(status: 'completed')
        SendWalkInWebhookJob.perform_later(@walk_in.id)
        redirect_to admin_root_path, notice: "Atendimento concluído com sucesso."
      else
        redirect_to admin_walk_in_path(@walk_in), alert: "Erro ao concluir atendimento."
      end
    end

    def destroy
      @walk_in.destroy
      redirect_to admin_root_path, notice: "Check-in removido com sucesso."
    end

    private

    def set_walk_in
      # Attendants only manage walk-ins from their unit if restricted
      scope = WalkIn.all
      if current_user.unit_id.present?
        scope = scope.where(unit_id: current_user.unit_id)
      end
      @walk_in = scope.find(params[:id])
    end

    def walk_in_params
      params.require(:walk_in).permit(
        :link_conversa,
        patient_attributes: [
          :id, :nome, :cpf, :data_nascimento, :sexo_biologico,
          :telefone, :whatsapp, :cidade_atendimento,
          :cobertura_tipo, :convenio, :plano, :numero_carteira, :validade_carteira
        ],
        requested_exams_attributes: [
          :id, :codigo, :descricao, :acuracia, :_destroy
        ]
      )
    end
  end
end
