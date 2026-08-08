class ApplicationController < ActionController::Base
  # No tenant logic — each deployment IS the laboratory.
  # Identity is configured via environment variables (LAB_NAME, APP_HOST).
end
