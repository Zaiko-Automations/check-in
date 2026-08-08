class CheckinController < ApplicationController
  layout 'checkin'

  before_action :load_unit

  def show
    # Render the multi-step form
  end

  def create
    @walk_in = WalkIn.new(unit: @unit)

    ActiveRecord::Base.transaction do
      @walk_in.save!

      # Build patient record and default city
      patient_data = patient_params
      patient_data[:cidade_atendimento] = @unit.city if patient_data[:cidade_atendimento].blank?

      @patient = @walk_in.build_patient(patient_data)
      @patient.save!

      # Attach images if provided
      if params[:carteira_convenio].present?
        @walk_in.carteira_convenio.attach(params[:carteira_convenio])
      end

      if params[:requisicao_medica].present?
        @walk_in.requisicao_medica.attach(params[:requisicao_medica])
      end

      if params[:documento].present?
        @walk_in.documento.attach(params[:documento])
      end
    end

    SendWalkInWebhookJob.perform_later(@walk_in.id)

    redirect_to checkin_success_path(token: @unit.token), notice: "Check-in confirmado!"

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  end

  def success
    # Render success/confirmation screen
  end

  private

  def load_unit
    @unit = Unit.find_by!(token: params[:token], active: true)
  rescue ActiveRecord::RecordNotFound
    render plain: "QR Code inválido ou unidade inativa.", status: :not_found
  end

  def patient_params
    params.permit(
      :nome, :cpf, :data_nascimento, :sexo_biologico,
      :telefone, :whatsapp, :cidade_atendimento,
      :cobertura_tipo,
      :convenio, :plano, :numero_carteira, :validade_carteira
    )
  end
end
