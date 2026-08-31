module Admin
  class UnitsController < BaseController
    before_action :require_admin!
    before_action :set_unit, only: [:show, :edit, :update, :destroy]

    def index
      @units = Unit.order(:name)
    end

    def show
      @qr_svg = @unit.qr_svg
    end

    def new
      @unit = Unit.new
    end

    def create
      @unit = Unit.new(unit_params)

      if @unit.save
        redirect_to admin_unit_path(@unit), notice: "Unidade criada com sucesso! QR code disponível abaixo."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @unit.update(unit_params)
        redirect_to admin_unit_path(@unit), notice: "Unidade atualizada."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @unit.update!(active: false)
      redirect_to admin_units_path, notice: "Unidade desativada."
    end

    private

    def set_unit
      @unit = Unit.find(params[:id])
    end

    def unit_params
      params.require(:unit).permit(:name, :address, :city, :active)
    end
  end
end
