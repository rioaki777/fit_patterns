class WeeklySummaryCardComponent < ViewComponent::Base
  def initialize(presenter:)
    @presenter = presenter
  end
end
