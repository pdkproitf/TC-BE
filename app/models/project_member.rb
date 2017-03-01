class ProjectMember < ApplicationRecord
    belongs_to :project
    belongs_to :member

    validates_uniqueness_of :project_id, scope: :member_id

    def archive
        update_attributes(is_archived: true)
    end

    def unarchive
        update_attributes(is_archived: false)
    end
end
