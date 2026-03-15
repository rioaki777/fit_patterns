class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :weight_entries, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :weekly_reports, dependent: :destroy

  def admin?
    false
  end
end
