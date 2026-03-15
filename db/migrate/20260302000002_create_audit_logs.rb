class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.string :event, null: false
      t.integer :user_id
      t.jsonb :payload

      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
  end
end
