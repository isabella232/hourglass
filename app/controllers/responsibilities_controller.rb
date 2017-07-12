class ResponsibilitiesController < ApplicationController
  def index
    @responsibilities = Responsibility.ordered # TODO: .active
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_attributes)

    if @user.save
      redirect_to users_path
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])

    if @user.update(user_attributes)
      redirect_to users_path
    else
      render :edit
    end
  end

  def destroy
    @user = User.find(params[:id])

    @user.archive

    redirect_to users_path
  end

  def reorder
    Responsibility.reorder(params[:id], params[:position])

    head :no_content
  end

  private

  def user_attributes
    params.require(:user).permit(
      :email,
      :harvest_id,
      :name,
      :slack_id,
      :time_zone,
      :zenefits_name,
      tags: [],
      workdays: []
    )
  end
end
