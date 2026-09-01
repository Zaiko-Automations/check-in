Rails.application.routes.draw do
  # Devise auth for admin users
  devise_for :users, path: 'admin/auth',
             controllers: {
               sessions:  'users/sessions',
               passwords: 'users/passwords'
             }

  # ─── Checkin público (formulário do paciente) ───────────────────────────────
  get  '/checkin/:token',         to: 'checkin#show',    as: :checkin
  post '/checkin/:token',         to: 'checkin#create',  as: :checkin_submit
  get  '/checkin/:token/success', to: 'checkin#success', as: :checkin_success

  # ─── Admin (recepção) ───────────────────────────────────────────────────────
  namespace :admin do
    root to: 'dashboard#index'
    resources :units
    resources :users
    resources :walk_ins, only: [:index, :show, :update, :destroy] do
      member do
        patch :complete
      end
      collection do
        delete :bulk_destroy
        post   :bulk_destroy
      end
    end
    # Configurações de webhook e identidade do laboratório
    resource :settings, only: [:edit, :update]
  end

  # ─── API pública (dashboard central consulta cada instância) ─────────────────
  namespace :api do
    namespace :v1 do
      get  'stats', to: 'stats#show'
      post 'walk_ins/:id/callback', to: 'walk_ins#callback'
      post 'walk_ins/callback',     to: 'walk_ins#callback'
      post 'callback',              to: 'walk_ins#callback'
    end
  end

  # Redirect root to admin
  root to: redirect('/admin')

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
