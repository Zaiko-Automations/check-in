module Admin
  class UsersController < BaseController
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
        redirect_to admin_users_path, notice: "Usuário criado com sucesso!"
      else
        @units = Unit.active.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @units = Unit.active.order(:name)
    end

    def update
      # Allow updating without password if left blank
      filtered_params = user_params
      if filtered_params[:password].blank? && filtered_params[:password_confirmation].blank?
        filtered_params.delete(:password)
        filtered_params.delete(:password_confirmation)
      end

      if @user.update(filtered_params)
        redirect_to admin_users_path, notice: "Usuário atualizado com sucesso!"
      else
        @units = Unit.active.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Você não pode excluir sua própria conta de usuário."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "Usuário removido com sucesso."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation, :unit_id)
    end
  end
end
