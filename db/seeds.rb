# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

id = 1 # change id of president of company
user = User.find(id)
5.times do |i|
    Client.create(name: "Client #{i}", user_id: user.id)
end

users = User.where.not(id: id)
clients = Client.all
categories = Category.all

# add member to company
users.each do |employee|
    Membership.create!(
        employer_id: user.id,
        employee_id: employee.id
    )
end

clients.each_with_index do |item, index|
    # create project
    project = user.projects.create(name: "Project #{index + 10}", client_id: item.id, background: 'blue', report_permission: 1)

    # add member to project
    users.each do |u|
        u.projects.create(name: "Project #{index + 10}", client_id: item.id, background: 'blue', report_permission: 1)
        project.project_user_roles.create(user_id: u.id, role_id: Role.last.id)
        categories.each do |category|
            # add category to project
            project_category = project.project_categories.create(category_id: category.id)
            # choice category for user
            project_category_user = project_category.project_category_users.create(user_id: user.id)
            # add task for project_category_user
            task = project_category_user.tasks.create(name: "Task  #{index}")
            # add timer for task
            task.timers.create(start_time: Time.now, stop_time: Time.now + 1)
        end
    end
end
