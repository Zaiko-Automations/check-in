# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# Permite scripts inline (onclick/inline scripts), estilos inline, Google Fonts e Viacep API.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https, :data
    policy.font_src    :self, :https, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :https, :data, "blob:"
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, :unsafe_eval
    policy.style_src   :self, :https, :unsafe_inline, "https://fonts.googleapis.com"
    policy.connect_src :self, :https, "https://viacep.com.br", "https://*.zaikohub.com.br"
    policy.frame_ancestors :none
  end
end
