class Task < ApplicationRecord
    belongs_to :category_member
    has_many :timers, dependent: :destroy

    def get_tracked_time
        sum = 0
        if timers
            timers.each do |timer|
                sum += timer.get_tracked_time
            end
        end
        sum
    end
end
