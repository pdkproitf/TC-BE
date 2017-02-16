class ProjectCategoryUser < ApplicationRecord
    belongs_to :project_category, optional: true
    belongs_to :user
    has_many :tasks, dependent: :destroy
    validates_uniqueness_of :project_category_id, scope: :user_id, if: 'project_category_id.present?'

    def get_tracked_time
        sum = 0
        if tasks
            tasks.each do |task|
                sum += task.get_tracked_time
            end
        end
        sum
    end
end
