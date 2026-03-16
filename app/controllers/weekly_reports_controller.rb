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
    @errors = []

    # インライン バリデーション
    @errors << "開始日を入力してください" if period_start.nil?
    @errors << "終了日を入力してください" if period_end.nil?

    if period_start && period_end
      @errors << "開始日は終了日より前の日付を指定してください" if period_start > period_end
      @errors << "終了日は未来日を指定できません" if period_end > Date.current
      @errors << "期間は31日以内にしてください" if (period_end - period_start).to_i >= 31
    end

    if @errors.any?
      render :new, status: :unprocessable_entity
      return
    end

    # Service Object で集計処理を委譲
    stats = WeeklyReport::Generate.call(user: current_user, start_date: period_start, end_date: period_end)

    # 保存
    @report = WeeklyReport.create!(
      user:         current_user,
      period_start:,
      period_end:,
      **stats
    )

    # 手動 監査ログ
    AuditLog.create!(
      auditable: @report,
      event:     "weekly_report_created",
      user_id:   current_user.id,
      payload:   { period_start:, period_end:, notified_at: nil }
    )

    # インライン 同期通知
    case channel
    when "email"
      WeeklyReportMailer.report_ready(@report).deliver_now
    when "slack"
      Rails.logger.info "[Slack] Weekly report ready: #{@report.id}"
    end

    @report.update!(notified_at: Time.current)

    redirect_to weekly_report_path(@report), notice: "レポートを生成しました"
  rescue ActiveRecord::RecordInvalid => e
    @errors = e.record.errors.full_messages
    render :new, status: :unprocessable_entity
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
