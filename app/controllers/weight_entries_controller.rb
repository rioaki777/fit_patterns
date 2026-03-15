class WeightEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_weight_entry, only: %i[show edit update destroy]

  # GET /weight_entries or /weight_entries.json
  def index
    @weight_entries = current_user.weight_entries.recent
  end

  # GET /weight_entries/1 or /weight_entries/1.json
  def show
  end

  # GET /weight_entries/new
  def new
    @weight_entry = current_user.weight_entries.new
  end

  # GET /weight_entries/1/edit
  def edit
  end

  # POST /weight_entries or /weight_entries.json
  def create
    @weight_entry = current_user.weight_entries.new(weight_entry_params)

    if @weight_entry.save
      redirect_to @weight_entry, notice: "記録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /weight_entries/1 or /weight_entries/1.json
  def update
    if @weight_entry.update(weight_entry_params)
      redirect_to @weight_entry, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /weight_entries/1 or /weight_entries/1.json
  def destroy
    @weight_entry.destroy!
    redirect_to weight_entries_url, notice: "削除しました"
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_weight_entry
      @weight_entry = current_user.weight_entries.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def weight_entry_params
      params.require(:weight_entry).permit(:recorded_on, :weight_g, :body_fat_bp, :note)
    end
end
