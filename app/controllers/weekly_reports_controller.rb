class WeeklyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_report, only: [ :show, :destroy ]
  before_action :authorize_resource!, only: [ :show, :destroy ]

  def index
    @reports = WeeklyReport.where(user: current_user).order(updated_at: :desc).limit(10)
  end

  def new
    @period_start = 1.week.ago.to_date
    @period_end   = Date.today
    @notification_channel = "email"
    @errors = []
  end

  def create
    period_start = Date.parse(params[:period_start].to_s) rescue nil
    period_end   = Date.parse(params[:period_end].to_s) rescue nil
    channel      = params[:notification_channel].presence || "email"

    @period_start = period_start
    @period_end   = period_end
    @notification_channel = channel

    # Command パターン: 例外でなく Result で成否を表現
    result = GenerateWeeklyReportCommand.call(
      user:         current_user,
      period_start:,
      period_end:,
      channel:
    )

    if result.success?
      redirect_to weekly_report_path(result.report), notice: "レポートを生成しました"
    else
      @errors = result.errors
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @report.destroy!
    redirect_to weekly_reports_path, notice: "レポートを削除しました"
  end

  private

  def set_report
    @report = WeeklyReport.find(params[:id])
  end

  def authorize_resource!
    unless @report.user_id == current_user.id
      redirect_to root_path, alert: "権限がありません"
    end
  end
end
