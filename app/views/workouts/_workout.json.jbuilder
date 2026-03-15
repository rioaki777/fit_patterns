json.extract! workout, :id, :recorded_on, :kind, :duration_min, :calories_kcal, :intensity, :note, :user_id, :created_at, :updated_at
json.url workout_url(workout, format: :json)
