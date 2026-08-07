# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.

puts "Limpando banco de dados..."
Patient.destroy_all
WalkIn.destroy_all
Unit.destroy_all
Tenant.destroy_all

puts "Criando tenant padrão (Lab Centro)..."
tenant = Tenant.create!(
  name: "Laboratório Centro",
  subdomain: "labcentro",
  active: true
)

puts "Criando unidades físicas..."
unit1 = Unit.create!(
  tenant: tenant,
  name: "Matriz Centro",
  address: "Av. Principal, 1000",
  city: "São Paulo",
  active: true
)

unit2 = Unit.create!(
  tenant: tenant,
  name: "Filial Sul",
  address: "Rua do Sul, 500",
  city: "São Paulo",
  active: true
)

puts "Concluído! Subdomínio para teste local: ?tenant=labcentro"
puts "URL da Unidade 1: #{unit1.checkin_url(host: 'localhost:3000')}"
puts "URL da Unidade 2: #{unit2.checkin_url(host: 'localhost:3000')}"
