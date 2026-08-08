module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:edit, :update]

    def index
      @users = User.includes(:unit).order(:email)
    end

    def edit
      @units = Unit.active.order(:name)
    end

    def update
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "Permissões do usuário atualizadas com sucesso!"
      else
        @units = Unit.active.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:unit_id)
    end
  end
end
