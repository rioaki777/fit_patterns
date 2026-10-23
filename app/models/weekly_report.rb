class WeeklyReport < ApplicationRecord
  belongs_to :user
  has_many :audit_logs, as: :auditable, dependent: :destroy

  validates :period_start, :period_end, presence: true
  validates :period_start, uniqueness: { scope: :user_id }

  scope :recently_modified, -> { order(updated_at: :desc).limit(10) }
  scope :created_this_week, -> { where(created_at: 1.week.ago..) }
end
