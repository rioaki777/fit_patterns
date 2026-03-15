class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true

  validates :event, presence: true

  scope :for, ->(record) { where(auditable: record) }
end
