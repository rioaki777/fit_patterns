class WeeklyReportPolicy
  def initialize(user, report)
    @user = user
    @report = report
  end

  def create?
    @user.present?
  end

  def show?
    @report.user_id == @user&.id
  end

  def destroy?
    @user&.admin?
  end
end
