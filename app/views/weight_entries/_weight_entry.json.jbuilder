json.extract! weight_entry, :id, :recorded_on, :weight_g, :body_fat_bp, :note, :user_id, :created_at, :updated_at
json.url weight_entry_url(weight_entry, format: :json)
