class GenerateWeeklyReportCommand
  Result = Struct.new(:success?, :report, :errors, keyword_init: true)

  def self.call(user:, form:)
    new(user:, form:).call
  end

  def initialize(user:, form:)
    @user = user
    @form = form
  end

  def call
    unless @form.valid?
      return Result.new(success?: false, report: nil, errors: @form.errors)
    end

    report = GenerateWeeklyReportWorkflow.call(user: @user, form: @form)
    Result.new(success?: true, report:, errors: nil)
  rescue => e
    Result.new(success?: false, report: nil, errors: [e.message])
  end
end
