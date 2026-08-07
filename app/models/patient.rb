class Patient < ApplicationRecord
  belongs_to :walk_in

  COBERTURA_TIPOS = %w[particular convenio].freeze
  SEXOS = { "M" => "Masculino", "F" => "Feminino" }.freeze

  validates :nome, presence: true
  validates :cpf, presence: true
  validates :cobertura_tipo, presence: true, inclusion: { in: COBERTURA_TIPOS }
  validate :cpf_valido

  def sexo_label
    SEXOS[sexo_biologico] || sexo_biologico
  end

  def convenio?
    cobertura_tipo == 'convenio'
  end

  def particular?
    cobertura_tipo == 'particular'
  end

  private

  def cpf_valido
    return if cpf.blank?
    limpo = cpf.gsub(/\D/, '')
    unless limpo.length == 11 && !limpo.match(/\A(.)\1{10}\z/) && checksum_valido?(limpo)
      errors.add(:cpf, 'não é válido')
    end
  end

  def checksum_valido?(limpo)
    digitos = limpo.chars.map(&:to_i)

    soma = 0
    9.times { |i| soma += digitos[i] * (10 - i) }
    mod = soma % 11
    d1 = mod < 2 ? 0 : 11 - mod
    return false if digitos[9] != d1

    soma = 0
    10.times { |i| soma += digitos[i] * (11 - i) }
    mod = soma % 11
    d2 = mod < 2 ? 0 : 11 - mod
    digitos[10] == d2
  end
end
