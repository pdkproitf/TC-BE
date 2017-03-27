class TimerSerializer < ActiveModel::Serializer
  attributes :id, :task, :start_time, :stop_time, :category_member_id,
             :project_id, :project_name, :category_name, :background
  belongs_to :task, serializer: TaskSerializer

  attr_reader :overtime_type, :start_time_overtime
  attribute :overtime_type, if: :overtime_type
  attribute :overtime, if: :overtime_type

  def initialize(timer, options = {})
    super(timer)
    @overtime_type = options[:overtime_type] || nil
    @start_time_overtime = options[:start_time_overtime] || nil
  end

  def overtime
    object.stop_time - start_time
  end

  def start_time
    return @start_time_overtime if @start_time_overtime.present?
    object.start_time
  end

  def category_member_id
    object.task.category_member.id
  end

  def project_id
    category = object.task.category_member.category
    return nil unless category
    category.project.id
  end

  def project_name
    category = object.task.category_member.category
    return nil unless category
    category.project.name
  end

  def category_name
    category = object.task.category_member.category
    return nil unless category
    category.name
  end

  def background
    category = object.task.category_member.category
    return nil unless category
    category.project.background
  end
end
