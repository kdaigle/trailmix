class Entry < ActiveRecord::Base
  belongs_to :import
  belongs_to :user

  scope :newest, -> { order("date, created_at DESC") }

  def for_today?
    date == Time.zone.now.in_time_zone(user.time_zone).to_date
  end

  def date
    super || created_at.in_time_zone(user.time_zone).to_date
  end
end
