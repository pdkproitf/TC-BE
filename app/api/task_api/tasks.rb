module TaskApi
    class Tasks < Grape::API
        prefix :api
        version 'v1', using: :accept_version_header
        #
        helpers do
        end

        resource :tasks do
            # => /api/v1/tasks/
            desc 'Get all tasks'
            get '/all' do
                Task.all
            end

            desc 'create new task'
            params do
                requires :task, type: Hash do
                    optional :name, type: String, desc: 'Task name'
                    optional :project_category_user_id, type: Integer, desc: 'Project category user ID'
                end
            end
            post '/new' do
                task_params = params['task']
                begin
                    task = Task.create!(
                        name: task_params['name'],
                        project_category_user_id: task_params['project_category_user_id']
                    )
                rescue => e
                    { error: 'project category user must exist' }
                end
                # task
            end

            desc 'edit a task'
            params do
                requires :task, type: Hash do
                    requires :name, type: String, desc: 'Task name'
                    requires :project_category_user_id, type: Integer, desc: 'Project category user ID'
                end
            end
            put ':id' do
                task_params = params['task']
                task = Task.find(params['id'])
                begin
                    task.update(
                        name: task_params['name'],
                        project_category_user_id: task_params['project_category_user_id']
                    )
                rescue => e
                    { error: 'project category user must exist' }
                end
                task
            end
        end
    end
end