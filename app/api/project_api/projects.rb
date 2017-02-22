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
            desc 'For test get all members in model project'
            params do
                requires :id, type: String, desc: 'Project ID'
                requires :order_by, type: String, values: ['id', 'first_name', 'last_name'], desc: 'Order by'
            end
            get '/test_getallmembers' do
              project = Project.find(params[:id])
              {"data": project.get_all_members(params[:order_by])}
            end

            desc 'For test is user joined to project in model user'
            params do
                requires :id, type: String, desc: 'Project ID'
            end
            get '/test_isjoinedproject' do
              authenticated!
              is_joined = @current_user.is_joined_project(params[:id])
              {"data": is_joined}
            end

            desc 'Get all projects that I own'
            get '/' do
                authenticated!
                project_list = @current_user.projects

                list = []
                project_list.each do |project|
                  member_list = []
                  project.project_user_roles.each do |member|
                      member_list.push(member.user)
                  end

                  item = {
                    "info": ProjectSerializer.new(project),
                    "tracked_time": project.get_tracked_time,
                    "member": member_list
                  }
                  list.push(item)
                end
                {data: list}
            end

            desc 'Get all projects that I join'
            get '/join' do
                authenticated!
                pcu_list = @current_user.project_category_users
                  .where.not(project_category_id: nil)
                  .joins(project_category: [{project: :client} , :category])
                  .select("project_category_users.id")
                  .select("project_categories.id as pc_id")
                  .select("projects.id as project_id", "projects.name as project_name", "projects.background")
                  .select("clients.id as client_id", "clients.name as client_name")
                  .select("categories.name as category_name")
                  .where(projects: {is_archived: false})
                  .order("projects.id asc") # Change order if you want

                  list = []
                  project_id_list = []
                  pcu_list.each do |pcu|
                    if !project_id_list.include?(pcu.project_id)
                      project_id_list.push(pcu.project_id)
                      item = {id: pcu.project_id, name: pcu.project_name, background: pcu.background}
                      item[:client] = {id: pcu.client_id, name: pcu.client_name}
                      item[:category] = []
                      list.push(item)
                    else
                      item = list.select do |hash|
                          hash[:id] == pcu.project_id
                      end
                      item = item.first
                    end
                    item[:category].push({id: pcu.pc_id, name: pcu.category_name, pcu_id: pcu.id})
                  end
                  {"data": list}
            end # End of join

            desc 'Get a project by id'
            params do
                requires :id, type: String, desc: 'Project ID'
            end
            get ':id' do
                authenticated!
                begin
                  project = @current_user.projects.find(params[:id])
                  project_hash = Hash.new
                  project_hash.merge!(ProjectSerializer.new(project).attributes)
                  project_hash[:client_name] = project.client[:name]
                  project_hash[:tracked_time] = project.get_tracked_time

                  pc_list = project.project_categories
                  list = []
                  pc_list.each do |pc|
                    item = Hash.new
                    item.merge!(ProjectCategorySerializer.new(pc))
                    item.delete(:project_id)
                    item.delete(:category_id)
                    item[:category] = CategorySerializer.new(pc.category)
                    item[:tracked_time] = pc.get_tracked_time

                    member_list = []
                    pc.project_category_users.each do |pcu|
                      member_hash = Hash.new
                      member_hash.merge!(ProjectCategoryUserSerializer.new(pcu))
                      member_hash.delete(:id)
                      member_hash.delete(:user_id)
                      role = ProjectUserRole.joins(:role).where(project_id: project.id, user_id: pcu.user.id).select("roles.id", "roles.name")
                      member_hash[:user] = UserSerializer.new(pcu.user)
                      member_hash[:role] = role
                      member_hash[:tracked_time] = pcu.get_tracked_time
                      member_list.push(member_hash)
                    end
                    item[:member] = member_list

                    list.push(item)
                  end
                  {"data":{
                    "info": project_hash,
                    "project_category": list
                    }
                  }
                rescue => e
                    return error!(I18n.t("project_not_found"), 404)
                end
            end

            desc 'create new project'
            params do
                 requires :project, type: Hash do
                    requires :name, type: String, desc: 'Project name.'
                    requires :client_id, type: Integer, desc: 'Client id'
                    optional :background, type: String, desc: 'Background color'
                    optional :is_member_report, type: Boolean, desc: 'Allow member to run report'
                    optional :member_roles, type: Array, desc: 'Member roles' do
                        requires :member_id, type: Integer, desc: 'Member id'
                        requires :is_pm, type: Boolean, desc: 'If member becomes Project Manager'
                    end
                    optional :category_members, type: Array, desc: 'Assign member to categories' do
                        requires :category_name, type: String, desc: 'Category name'
                        requires :is_billable, type: Boolean, desc: 'Billable'
                        requires :members, type: Array, desc: 'Member' do
                            requires :member_id, type: Integer, desc: 'Member id'
                        end
                    end
                end
            end
            post '/' do
              @current_member = Member.find(1)
              project_params = params[:project]

              # Current user has to be an admin or a PM
              if @current_member.role != 1 && @current_member.role != 2
                return error!(I18n.t("access_denied"), 400)
              end

              # Client has to belongs to the company of current user
              if !@current_member.company.clients.exists?(project_params[:client_id])
                return error!(I18n.t("client_not_found"), 400)
              end

              # Create new project object
              project = @current_member.projects.new

              # If background exists
              if project_params[:background]
                # Validate background here
                project.background = project_params[:background]
              end

              # If member_roles exists
              if project_params[:member_roles]
                project_params[:member_roles].each do |member_role|
                  # Check if member belongs to team
                  if !@current_member.company.members.exists?(member_role[:member_id])
                    return error!(I18n.t("not_joined_to_company"), 400)
                  end
                  # Add member in team to project
                  project.project_members.new(member_id: member_role[:member_id], is_pm: member_role[:is_pm])
                end

                # If category_members exists
                if project_params[:category_members]
                    project_params[:category_members].each do |category_member|
                      # Create new categories
                      category = project.categories.new(
                        name: category_member[:category_name],
                        is_billable: category_member[:is_billable]
                      )
                      #Check if company members were added to project
                      category_member[:members].each do |member|
                        if !project.project_members.find { |h| h[:member_id] == member[:member_id] }
                          return error!(I18n.t("not_added_to_project"), 400)
                        end
                        # Assign members to categories
                        category.category_members.new(member_id: member[:member_id])
                      end
                    end
                  end
                end

                project.name = project_params[:name]
                project.client_id = project_params[:client_id]

                if project_params[:is_member_report]
                  project.is_member_report = project_params[:is_member_report]
                end

                project.save!
            end # End of project add new

            desc 'Delete a project'
            params do
                requires :id, type: String, desc: 'Project ID'
            end
            delete ':id' do
                authenticated!
                status 200
                begin
                  project = @current_user.projects.find(params[:id])
                  project.destroy
                  {"message" => "Delete project successfully"}
                rescue => e
                  error!(I18n.t("project_not_found"), 400)
                end
            end
        end
    end
end
