module Api
  module V1
    class WalkInsController < ActionController::API
      before_action :authenticate_token!

      def callback
        raw_body = request.raw_post
        payload = if raw_body.present?
                    begin
                      JSON.parse(raw_body)
                    rescue JSON::ParserError
                      params.to_unsafe_h
                    end
                  else
                    params.to_unsafe_h
                  end

        extracted = parse_payload(payload, params[:id])

        walk_in_id = extracted[:walk_in_id]
        if walk_in_id.blank?
          render json: { error: "ID do atendimento (walk_in_id ou id) não encontrado no payload" }, status: :unprocessable_entity
          return
        end

        @walk_in = WalkIn.find_by(id: walk_in_id) || WalkIn.find_by(uid: walk_in_id)

        if @walk_in.nil?
          render json: { error: "Atendimento não encontrado: #{walk_in_id}" }, status: :not_found
          return
        end

        @patient = @walk_in.patient

        ActiveRecord::Base.transaction do
          # 1. Update Patient details
          if extracted[:patient_attrs].present?
            clean_patient_attrs = extracted[:patient_attrs].compact_blank
            if clean_patient_attrs.present?
              @patient.assign_attributes(clean_patient_attrs)
              @patient.save!(validate: false)
            end
          end

          # 2. Update WalkIn attributes (solicitante, data_pedido_medico, link_conversa, status)
          walk_in_updates = { status: 'pending' }
          walk_in_updates[:link_conversa] = extracted[:link_conversa] if extracted[:link_conversa].present?
          walk_in_updates[:solicitante_nome] = extracted[:solicitante_nome] if extracted[:solicitante_nome].present?
          walk_in_updates[:solicitante_conselho] = extracted[:solicitante_conselho] if extracted[:solicitante_conselho].present?
          walk_in_updates[:solicitante_especialidade] = extracted[:solicitante_especialidade] if extracted[:solicitante_especialidade].present?
          walk_in_updates[:data_pedido_medico] = extracted[:data_pedido_medico] if extracted[:data_pedido_medico].present?

          # Filter only existing columns in walk_ins table to be 100% migration-safe
          valid_columns = WalkIn.column_names
          safe_updates = walk_in_updates.select { |k, _| valid_columns.include?(k.to_s) }
          @walk_in.update_columns(safe_updates)

          # 3. Save / Recreate exams list
          if extracted[:exams].present?
            @walk_in.requested_exams.destroy_all
            extracted[:exams].each do |exam|
              next if exam[:descricao].blank? && exam[:codigo].blank?
              @walk_in.requested_exams.create!(
                codigo:    exam[:codigo],
                descricao: exam[:descricao],
                acuracia:  exam[:acuracia]
              )
            end
          end
        end

        Rails.logger.info "[Api::V1::WalkInsController Callback Success] WalkIn #{@walk_in.uid} atualizado com #{@walk_in.requested_exams.count} exames."

        render json: {
          message: "Walk-in atualizado com sucesso!",
          walk_in_id: @walk_in.uid,
          status: @walk_in.status,
          paciente: @patient.nome,
          solicitante: @walk_in.respond_to?(:solicitante_nome) ? @walk_in.solicitante_nome : nil,
          exames_total: @walk_in.requested_exams.count
        }, status: :ok
      rescue => e
        Rails.logger.error "[Api::V1::WalkInsController Callback Error] #{e.message}\n#{e.backtrace.first(5).join("\n")}"
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authenticate_token!
        token = request.headers['X-API-Token'] ||
                request.headers['Authorization']&.split(' ')&.last ||
                params[:token]
        expected_token = ENV['WEBHOOK_API_TOKEN'] || 'vida_lucas_secret_token_2026'

        if token.blank? || token != expected_token
          Rails.logger.warn("[Api::V1::WalkInsController] Token inválido ou ausente: #{token.inspect}")
          render json: { error: 'Unauthorized: Invalid or missing token' }, status: :unauthorized
        end
      end

      def is_present?(val)
        !val.nil? && !(val.is_a?(String) && val.strip.empty?)
      end

      def parse_payload(parsed, url_id)
        items = parsed.is_a?(Array) ? parsed : [parsed]

        walk_in_id = url_id.presence
        patient_attrs = {}
        exams = []
        link_conversa = nil
        solicitante_nome = nil
        solicitante_conselho = nil
        solicitante_especialidade = nil
        data_pedido_medico = nil

        items.each do |item|
          next unless item.is_a?(Hash)

          # 1. WalkIn ID & link conversa
          walk_in_id ||= item['walk_in_id'] || item['uid'] || item['id']
          link_conversa ||= item['link_conversa'] || item['conversa_url']

          # 2. Solicitante / Médico
          sol = item['solicitante'] || item['medico'] || item['doctor']
          if sol.is_a?(Hash)
            solicitante_nome ||= sol['nome'] || sol['name'] || sol['medico']
            solicitante_conselho ||= sol['numero_conselho'] || sol['conselho'] || sol['crm']
            solicitante_especialidade ||= sol['especialidade'] || sol['specialty']
          end
          solicitante_nome ||= item['solicitante_nome']
          solicitante_conselho ||= item['solicitante_conselho']
          solicitante_especialidade ||= item['solicitante_especialidade']

          # Data pedido médico
          data_pedido_medico ||= item['data_pedido_medico']

          # 3. Root level fields
          if is_present?(item['cidade_atendimento'])
            patient_attrs[:cidade_atendimento] ||= item['cidade_atendimento']
          end
          if is_present?(item['tipo']) || is_present?(item['cobertura_tipo'])
            patient_attrs[:cobertura_tipo] ||= item['cobertura_tipo'] || item['tipo']
          end

          # 4. Paciente / Patient object
          paciente = item['paciente'] || item['patient']
          if paciente.is_a?(Hash)
            data_pedido_medico ||= paciente['data_pedido_medico']
            paciente.each do |k, v|
              next unless is_present?(v)
              case k.to_s
              when 'nome', 'name', 'paciente_nome'
                patient_attrs[:nome] ||= v.to_s.strip
              when 'cpf'
                patient_attrs[:cpf] ||= v.to_s.strip
              when 'data_nascimento', 'birth_date'
                patient_attrs[:data_nascimento] ||= v
              when 'sexo_biologico', 'sexo', 'gender'
                patient_attrs[:sexo_biologico] ||= v.to_s.strip
              when 'telefone', 'phone'
                patient_attrs[:telefone] ||= v.to_s.strip
              when 'whatsapp'
                patient_attrs[:whatsapp] = (v.to_s.downcase == 'true' || v == true || v == 1)
              when 'cidade_atendimento'
                patient_attrs[:cidade_atendimento] ||= v
              when 'cobertura_tipo', 'tipo'
                patient_attrs[:cobertura_tipo] ||= v
              when 'convenio'
                patient_attrs[:convenio] ||= v
              when 'plano'
                patient_attrs[:plano] ||= v
              when 'numero_carteira'
                patient_attrs[:numero_carteira] ||= v
              when 'validade_carteira'
                patient_attrs[:validade_carteira] ||= v
              when 'logradouro', 'numero', 'bairro', 'cidade', 'uf', 'cep', 'complemento'
                patient_attrs[k.to_sym] ||= v
              end
            end
          end

          # 5. Nested markdown JSON in content.parts (Gemini LLM direct response)
          parts = item.dig('content', 'parts')
          if parts.is_a?(Array)
            parts.each do |part|
              text = part['text']
              next unless text.is_a?(String)

              if text =~ /```(?:json)?\s*(\{.*?\})\s*```/m || text =~ /(\{.*\})/m
                begin
                  gemini_data = JSON.parse($1)
                  dados = gemini_data['dados'] || gemini_data
                  if dados.is_a?(Hash)
                    data_pedido_medico ||= dados['data_pedido_medico']
                    solicitante_nome ||= dados['solicitante_nome']
                    solicitante_conselho ||= dados['solicitante_conselho']
                    solicitante_especialidade ||= dados['solicitante_especialidade']

                    dados.each do |k, v|
                      next unless is_present?(v)
                      case k.to_s
                      when 'nome', 'paciente_nome'
                        patient_attrs[:nome] ||= v.to_s.strip
                      when 'cpf'
                        patient_attrs[:cpf] ||= v.to_s.strip
                      when 'data_nascimento'
                        patient_attrs[:data_nascimento] ||= v
                      when 'sexo_biologico', 'sexo'
                        patient_attrs[:sexo_biologico] ||= v.to_s.strip
                      end
                    end
                  end
                rescue => e
                  # ignore parse error
                end
              end
            end
          end

          # 6. Exames at root level
          raw_exams = item['exames_solicitados'] || item['exams']
          if raw_exams.is_a?(Array)
            raw_exams.each do |ex|
              next unless ex.is_a?(Hash)
              desc = ex['descricao'] || ex['description'] || ex['nome']
              next unless is_present?(desc)
              acc = ex['accuracy'] || ex['acuracia']
              exams << {
                codigo: ex['codigo'],
                descricao: desc.to_s.strip,
                acuracia: acc ? "#{acc}%" : nil
              }
            end
          end

          # 7. Requisicoes medicas (multiple pages)
          reqs = item['requisicoes_medicas']
          if reqs.is_a?(Array)
            reqs.compact.each do |req|
              next unless req.is_a?(Hash)
              dados = req['dados'] || req
              solicitante_nome ||= dados['solicitante_nome']
              solicitante_conselho ||= dados['solicitante_conselho']
              solicitante_especialidade ||= dados['solicitante_especialidade']
              data_pedido_medico ||= dados['data_pedido_medico']

              nested_exams = dados['exames_solicitados']
              if nested_exams.is_a?(Array)
                nested_exams.each do |ex|
                  next unless ex.is_a?(Hash)
                  desc = ex['descricao'] || ex['description'] || ex['nome']
                  next unless is_present?(desc)
                  acc = ex['accuracy'] || ex['acuracia']
                  exams << {
                    codigo: ex['codigo'],
                    descricao: desc.to_s.strip,
                    acuracia: acc ? "#{acc}%" : nil
                  }
                end
              end
            end
          end
        end

        # Deduplicate exams by case-insensitive description
        unique_exams = exams.uniq { |e| e[:descricao].downcase.strip }

        {
          walk_in_id: walk_in_id,
          patient_attrs: patient_attrs,
          exams: unique_exams,
          link_conversa: link_conversa,
          solicitante_nome: solicitante_nome,
          solicitante_conselho: solicitante_conselho,
          solicitante_especialidade: solicitante_especialidade,
          data_pedido_medico: data_pedido_medico
        }
      end
    end
  end
end
