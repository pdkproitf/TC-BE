module ProjectApi
    class Projects < Grape::API
        prefix :api
        version 'v1', using: :accept_version_header
        #
        helpers do
            def project_category_user_create(project_category_id, user_id)
                ProjectCategoryUser.create!(
                    project_category_id: project_category_id,
                    user_id: user_id
                )
            end

            def project_category_create(project_id, category_id, billable)
                ProjectCategory.create!(
                    project_id: project_id,
                    category_id: category_id,
                    billable: billable
                )
            end
        end

        resource :projects do
            # => /api/v1/projects/
            desc 'Get all projects'
            get '/all' do
                authenticated!
                @current_user.projects
            end

            desc 'Get a project by id'
            params do
                requires :id, type: String, desc: 'Project ID'
            end
            get ':id' do
                authenticated!
                @current_user.projects.where(id: params[:id]).first!
            end

            desc 'create new project'
            params do
                requires :project, type: Hash do
                    requires :name, type: String, desc: 'Project name.'
                    requires :client_id, type: Integer, desc: 'Client id'
                    requires :background, type: String, desc: 'Background color'
                    requires :report_permission, type: Integer, desc: 'Report permission'
                    optional :member_roles, type: Array, desc: 'Member roles' do
                        requires :user_id, type: Integer, desc: 'User id'
                        requires :role_id, type: Integer, desc: 'Role id'
                    end
                    optional :category_members, type: Hash do
                        requires :existing, type: Array, desc: 'Existing categories' do
                            requires :category_id, type: Integer, desc: 'Category id'
                            requires :members, type: Array, desc: 'Member' do
                                requires :user_id, type: Integer, desc: 'User id'
                            end
                            requires :billable, type: Boolean, desc: 'Billable'
                        end
                        optional :new, type: Array, desc: 'New categories' do
                            requires :category_name, type: String, desc: 'New category name'
                            requires :members, type: Array, desc: 'Member' do
                                requires :user_id, type: Integer, desc: 'User id'
                            end
                            requires :billable, type: Boolean, desc: 'Billable'
                        end
                    end
                end
            end
            post '/new' do
                authenticated!

                project_params = params['project']
                project = @current_user.projects.create!(
                    name: project_params['name'],
                    client_id: project_params['client_id'],
                    background: project_params['background'],
                    report_permission: project_params['report_permission']
                )

                # Add member role (option)
                if project_params['member_roles']
                    member_roles_params = project_params['member_roles']
                    member_roles_params.each do |member_roles|
                        project.project_user_roles.create!(
                            project_id: project.id,
                            user_id: member_roles.user_id,
                            role_id: member_roles.role_id
                        )
                    end
                end

                # Add project category (option)
                if project_params['category_members']
                    # For existing categories
                    if project_params['category_members']['existing']
                        existingList = project_params['category_members']['existing']
                        existingList.each do |existing|
                            project_category = project_category_create(
                                project.id,
                                existing.category_id,
                                existing.billable
                            )
                            existing['members'].each do |member|
                                project_category_user_create(project_category.id, member.user_id)
                            end
                        end
                    end

                    # For new categories
                    if project_params['category_members']['new']
                        newList = project_params['category_members']['new']
                        newList.each do |new_cate|
                            category = Category.create!(name: new_cate['category_name'])
                            project_category = project_category_create(
                                project.id,
                                category.id,
                                new_cate.billable
                            )
                            new_cate['members'].each do |member|
                                project_category_user_create(project_category.id, member.user_id)
                            end
                        end
                    end
                end

                project
            end # End of project add new

            desc 'Delete a project'
            params do
                requires :id, type: String, desc: 'Project ID'
            end
            delete ':id' do
                authenticated!
                project = @current_user.projects
                'hehe'
                # project.destroy
            end
        end
    end
end
