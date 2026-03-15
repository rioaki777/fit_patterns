class WorkoutsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_workout, only: %i[show edit update destroy]

  def index
    @workouts = current_user.workouts.recent
  end

  def show; end
  def new
    @workout = current_user.workouts.new
  end

  def edit; end

  def create
    @workout = current_user.workouts.new(workout_params)

    if @workout.save
      redirect_to @workout, notice: "記録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @workout.update(workout_params)
      redirect_to @workout, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workout.destroy!
    redirect_to workouts_url, notice: "削除しました"
  end

  private

  def set_workout
    @workout = current_user.workouts.find(params[:id])
  end

  def workout_params
    params.require(:workout).permit(:recorded_on, :kind, :duration_min, :calories_kcal, :intensity, :note)
  end
end
