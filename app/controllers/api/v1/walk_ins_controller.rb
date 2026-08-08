module Api
  module V1
    class WalkInsController < ActionController::API
      before_action :authenticate_token!

      def callback
        # Find by ID or UUID
        @walk_in = WalkIn.find_by(id: params[:id]) || WalkIn.find_by!(uid: params[:id])
        @patient = @walk_in.patient

        ActiveRecord::Base.transaction do
          # 1. Update Patient details
          if params[:patient].present?
            @patient.update!(patient_params)
          end

          # 2. Update WalkIn attributes
          @walk_in.update!(
            status: 'pending', # Reset back to pending so reception sees it
            link_conversa: params[:link_conversa] || @walk_in.link_conversa
          )

          # 3. Recreate exams list
          if params[:exams].is_a?(Array)
            @walk_in.requested_exams.destroy_all
            params[:exams].each do |exam|
              next if exam[:descricao].blank? && exam[:codigo].blank?
              @walk_in.requested_exams.create!(
                codigo:    exam[:codigo],
                descricao: exam[:descricao],
                acuracia:  exam[:acuracia]
              )
            end
          end
        end

        render json: { message: "Walk-in updated successfully", status: @walk_in.status }, status: :ok
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_token!
        token = request.headers['X-API-Token'] || request.headers['Authorization']&.split(' ')&.last
        expected_token = ENV['WEBHOOK_API_TOKEN'] || 'vida_lucas_secret_token_2026'

        if token.blank? || token != expected_token
          render json: { error: 'Unauthorized: Invalid or missing token' }, status: :unauthorized
        end
      end

      def patient_params
        params.require(:patient).permit(
          :nome, :cpf, :data_nascimento, :sexo_biologico,
          :telefone, :whatsapp, :cidade_atendimento,
          :cobertura_tipo, :convenio, :plano, :numero_carteira, :validade_carteira,
          :logradouro, :numero, :bairro, :cidade, :uf, :cep, :complemento
        )
      end
    end
  end
end
