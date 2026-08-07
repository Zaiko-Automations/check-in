Rails.application.routes.draw do
  # Devise auth for admin users
  devise_for :users, path: 'admin/auth', controllers: {
    sessions: 'users/sessions'
  }

  # ─── Checkin público (formulário do paciente) ───────────────────────────────
  get  '/checkin/:token',         to: 'checkin#show',    as: :checkin
  post '/checkin/:token',         to: 'checkin#create',  as: :checkin_submit
  get  '/checkin/:token/success', to: 'checkin#success', as: :checkin_success

  # ─── Admin (recepção) ───────────────────────────────────────────────────────
  namespace :admin do
    root to: 'dashboard#index'
    resources :units
    resources :walk_ins, only: [:index, :show] do
      member do
        patch :complete
      end
    end
  end

  # Redirect root to admin
  root to: redirect('/admin')

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
