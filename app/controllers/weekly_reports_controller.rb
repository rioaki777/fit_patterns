class WeeklyReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_report, only: [:show, :destroy]
  before_action :authorize!, only: [:show, :destroy]

  def index
    @reports = current_user.weekly_reports.recently_modified
  end

  def new
    @form = WeeklyReportForm.new(
      period_start: 1.week.ago.to_date,
      period_end: Date.today
    )
  end

  def create
    @form = WeeklyReportForm.new(weekly_report_params)
    policy = WeeklyReportPolicy.new(current_user, nil)
    return redirect_to root_path, alert: "権限がありません" unless policy.create?

    result = GenerateWeeklyReportCommand.call(user: current_user, form: @form)
    if result.success?
      redirect_to weekly_report_path(result.report), notice: "レポートを生成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @presenter = WeeklyReportPresenter.new(@report)
  end

  def destroy
    @report.destroy!
    redirect_to weekly_reports_path, notice: "レポートを削除しました"
  end

  private

  def set_report
    @report = WeeklyReport.find(params[:id])
  end

  def authorize!
    policy = WeeklyReportPolicy.new(current_user, @report)
    redirect_to root_path, alert: "権限がありません" unless policy.show?
  end

  def weekly_report_params
    params.require(:weekly_report_form).permit(:period_start, :period_end, :notification_channel)
  end
end
