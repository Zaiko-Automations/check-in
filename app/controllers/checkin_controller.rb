class CheckinController < ApplicationController
  layout 'checkin'

  before_action :load_unit

  def show
    @origem = params[:origem].presence || 'qrcode'
  end

  def create
    origem = params[:origem].presence || 'qrcode'
    prioridade = params[:prioridade].presence || 'geral'
    numero_senha = params[:numero_senha].to_s.strip.presence

    @walk_in = WalkIn.new(
      unit: @unit,
      origem: origem,
      prioridade: prioridade,
      numero_senha: numero_senha
    )

    ActiveRecord::Base.transaction do
      @walk_in.save!

      # Build patient record and default city
      patient_data = patient_params
      patient_data[:cidade_atendimento] = @unit.city if patient_data[:cidade_atendimento].blank?
      patient_data[:nome] = "Aguardando Leitura (IA)" if patient_data[:nome].blank?
      patient_data[:cpf] = "—" if patient_data[:cpf].blank?
      patient_data[:cobertura_tipo] = "particular" if patient_data[:cobertura_tipo].blank?

      @patient = @walk_in.build_patient(patient_data)
      @patient.save!

      # Attach foto_senha if provided
      if params[:foto_senha].present?
        @walk_in.foto_senha.attach(params[:foto_senha])
      end

      # Attach carteira_convenio if provided
      if params[:carteira_convenio].present?
        @walk_in.carteira_convenio.attach(params[:carteira_convenio])
      end

      # Attach requisicoes_medicas if provided
      if params[:requisicoes_medicas].present?
        @walk_in.requisicoes_medicas.attach(params[:requisicoes_medicas])
      end

      # Attach documento (RG/CNH) if provided
      if params[:documento].present?
        @walk_in.documento.attach(params[:documento])
      end
    end

    SendWalkInWebhookJob.perform_later(@walk_in.id, 'extraction')

    redirect_to checkin_success_path(token: @unit.token, walk_in_id: @walk_in.uid, senha: @walk_in.numero_senha), notice: "Check-in confirmado com sucesso!"

  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  end

  def success
    @walk_in = WalkIn.find_by(uid: params[:walk_in_id]) if params[:walk_in_id].present?
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
