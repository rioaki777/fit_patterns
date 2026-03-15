module Trackable
  extend ActiveSupport::Concern

  included do
    scope :recently_modified, -> { order(updated_at: :desc).limit(10) }
    scope :created_this_week, -> { where(created_at: 1.week.ago..) }

    after_create  { Rails.logger.info "[Trackable] #{self.class.name} created: #{id}" }
    after_update  { Rails.logger.info "[Trackable] #{self.class.name} updated: #{id}" }
  end

  def age_in_days
    (Date.today - created_at.to_date).to_i
  end
end
