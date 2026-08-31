module Admin
  class UsersController < BaseController
    before_action :require_admin!
    before_action :set_user, only: [:edit, :update, :destroy]

    def index
      @users = User.includes(:unit).order(:email)
    end

    def new
      @user = User.new
      @units = Unit.active.order(:name)
    end

    def create
      @user = User.new(user_params)

      if @user.save
        redirect_to admin_users_path, notice: "Usuário #{@user.email} criado com sucesso!"
      else
        @units = Unit.active.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @units = Unit.active.order(:name)
    end

    def update
      filtered = user_params
      # Don't update password if left blank
      if filtered[:password].blank? && filtered[:password_confirmation].blank?
        filtered.delete(:password)
        filtered.delete(:password_confirmation)
      end

      if @user.update(filtered)
        redirect_to admin_users_path, notice: "Usuário #{@user.email} atualizado com sucesso!"
      else
        @units = Unit.active.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Você não pode excluir sua própria conta."
        return
      end

      email = @user.email
      @user.destroy
      redirect_to admin_users_path, notice: "Usuário #{email} removido com sucesso."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :unit_id, :role)
    end
  end
end
