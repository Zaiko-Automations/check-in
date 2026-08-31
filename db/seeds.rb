# Seeds — Check-in Expresso
# Idempotente: pode ser re-executado sem duplicar registros.

puts "═══ Check-in Expresso — Seeds ═══"

# ─── Usuário admin padrão ────────────────────────────────────────────────────
# Para personalizar: ADMIN_EMAIL=seu@email.com ADMIN_PASSWORD=SenhaForte123 rails db:seed
admin_email    = ENV.fetch('ADMIN_EMAIL', 'admin@checkin.local')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'Checkin@2026!')

admin = User.find_by(email: admin_email)
if admin.nil?
  User.create!(
    email:                 admin_email,
    password:              admin_password,
    password_confirmation: admin_password,
    role:                  'admin'
  )
  puts "✅ Usuário admin criado: #{admin_email} (role: admin)"
else
  # Ensure existing admin has the admin role (migration safety)
  if admin.role != 'admin'
    admin.update_columns(role: 'admin')
    puts "✅ Role 'admin' atribuída ao usuário existente: #{admin_email}"
  else
    puts "ℹ️  Usuário admin já existe: #{admin_email} (role: #{admin.role})"
  end
end

# ─── Unidade padrão (se nenhuma existir) ─────────────────────────────────────
if Unit.none?
  lab_name = ENV.fetch('LAB_NAME', 'Check-in Expresso')
  unit = Unit.create!(
    name:    "Recepção Principal",
    address: "",
    city:    "",
    active:  true
  )
  puts "✅ Unidade padrão criada: #{unit.name}"
  puts "   QR Code URL: #{unit.checkin_url}"
else
  puts "ℹ️  Unidades já existem (#{Unit.count}), pulando criação."
end

puts "═══ Seeds concluídos! ═══"
