module ReportHelper
  class Report
    include Datetimes::Week
    include HolidayHelper

    def initialize(reporter, begin_date, end_date, options = {})
      @reporter = reporter
      @begin_date = begin_date.to_date
      @end_date = end_date.to_date
      @client = options[:client] || nil
      @member = options[:member] || nil
      @view = options[:view] || nil
      @working_time_per_day = reporter.company.working_time_per_day
      @working_time_per_week = reporter.company.working_time_per_week
      @begin_week = reporter.company.begin_week
      @overtime_type = { holiday: 'Holiday', weekend: 'Weekend', normal: 'Normal' }
    end

    def report_by_time
      { people: report_people, projects: report_projects }
    end

    def report_by_project
      project_options = { each_serializer: ProjectSerializer, begin_date: @begin_date, end_date: @end_date,
                          members_serialized: false, chart_serialized: true, categories_serialized: true, view: @view }
      ActiveModel::Serializer::CollectionSerializer.new(@reporter.get_projects, project_options)
    end

    def report_by_project_export
      project_options = { each_serializer: ProjectSerializer, begin_date: @begin_date, end_date: @end_date,
                          members_serialized: false, categories_serialized: true, perfect_tasks_serialized: true, view: @view }
      ActiveModel::Serializer::CollectionSerializer.new(@reporter.get_projects, project_options)
    end

    def report_by_member
      return nil if @member.nil?
      member_options = { begin_date: @begin_date, end_date: @end_date, tracked_time_serialized: true }
      result = {}
      result.merge!(MembersSerializer.new(@member, member_options))
      result[:projects] = member_projects
      result[:tasks] = member_tasks
      result[:overtime] = member_overtime(@member)
      result[:timer] = member_timer(@member)
      result
    end

    def report_member_tasks
      member_tasks.as_json
    end

    private

    # ===================== Report Only by Time helper methods =================
    # Report people
    def report_people
      person_options = { begin_date: @begin_date, end_date: @end_date, tracked_time_serialized: true }
      # As staff, return only data of the staff else As Admin and Super PM, return data of all member in company
      @reporter.member? ? members = Array(@reporter) : members = @reporter.company.members
      people = []
      members.each do |member|
        person = {}
        person.merge!(MembersSerializer.new(member, person_options))
        member_overtime(member).present? ? person[:overtime] = true : person[:overtime] = false
        people.push(person)
      end
      people
    end

    # Report projects
    def report_projects
      project_options = { begin_date: @begin_date, end_date: @end_date, members_serialized: false }
      projects = []
      @reporter.get_projects.order(:name).each do |project|
        projects.push(ProjectSerializer.new(project, project_options))
      end
      projects
    end

    # ================== Report Only by Time helper methods ends ===============
    # ======================= Report by Member helper methods ==================
    def member_projects
      result = []
      member_joined_categories(@member).each do |assigned_category|
        item = result.find { |h| h[:id] == assigned_category[:project_id] }
        unless item
          item = { id: assigned_category[:project_id], name: assigned_category[:project_name] }
          item[:background] = assigned_category[:background]
          item[:client] = { id: assigned_category[:client_id], name: assigned_category[:client_name] }
          item[:category] = []
          item[:chart] = {}
          result.push(item)
        end
        item[:category].push(
          name: assigned_category[:category_name],
          category_member_id: assigned_category[:category_member_id],
          tracked_time: assigned_category.tracked_time(@begin_date, @end_date)
        )
        case @view
        when 'day'
          (@begin_date..@end_date).each do |date|
            unless item[:chart][date]
              item[:chart][date] = {}
              item[:chart][date][:billable] = 0
              item[:chart][date][:unbillable] = 0
            end
            tracked_time = assigned_category.tracked_time(date, date)
            if assigned_category.category.is_billable
              item[:chart][date][:billable] += tracked_time
            else
              item[:chart][date][:unbillable] += tracked_time
            end
          end
        when 'month'
          begin_date_month = @begin_date.strftime('%Y-%m')
          end_date_month = @end_date.strftime('%Y-%m')
          next_end_date_month = (Date.new(@end_date.year, @end_date.month, -1) + 1).strftime('%Y-%m')
          month = begin_date_month
          month_begin_date = @begin_date
          month_end_date = Date.new(@begin_date.year, @begin_date.month, -1)

          until month == next_end_date_month
            month == begin_date_month ? month_begin_date = @begin_date : month_begin_date = month_end_date + 1
            month == end_date_month ? month_end_date = @end_date : month_end_date = Date.new(month_begin_date.year, month_begin_date.month, -1)

            unless item[:chart][month]
              item[:chart][month] = {}
              item[:chart][month][:billable] = 0
              item[:chart][month][:unbillable] = 0
            end

            tracked_time = assigned_category.tracked_time(month_begin_date, month_end_date)
            if assigned_category.category.is_billable
              item[:chart][month][:billable] += tracked_time
            else
              item[:chart][month][:unbillable] += tracked_time
            end

            month = (Date.new(month_end_date.year, month_end_date.month, -1) + 1).strftime('%Y-%m')
          end
        when 'year'
          year = @begin_date.year
          until year == @end_date.year + 1
            year == @begin_date.year ? year_begin_date = @begin_date : year_begin_date = Date.new(year, 0o1, 0o1)
            year == @end_date.year ? year_end_date = @end_date : year_end_date = Date.new(year, 12, 31)

            unless item[:chart][year]
              item[:chart][year] = {}
              item[:chart][year][:billable] = 0
              item[:chart][year][:unbillable] = 0
            end

            tracked_time = assigned_category.tracked_time(year_begin_date, year_end_date)
            if assigned_category.category.is_billable
              item[:chart][year][:billable] += tracked_time
            else
              item[:chart][year][:unbillable] += tracked_time
            end

            year += 1
          end
        end
      end
      result
    end

    def member_tasks
      tasks = []
      task_options = { begin_date: @begin_date, end_date: @end_date }
      @member.perfect_tasks.each do |task|
        customized_task = ReportTaskSerializer.new(task, task_options)
        tasks.push(customized_task) if customized_task.tracked_time > 0
      end
      tasks
    end

    def week_info(week_start_date, member)
      # Get all holidays in week
      holidays = holidays_in_week(@reporter.company, week_start_date)
      holidays_not_weekend = holidays.select { |holiday| holiday.wday != 0 && holiday.wday != 6 }
      # Calculate working time that has to do in week
      week_working_hour = @working_time_per_week - holidays_not_weekend.length * @working_time_per_day
      # Start to create week's info
      week = { working_time: week_working_hour * 3600 }
      week[:overtime] = week_working_time(week_start_date, member) - week[:working_time]
      week[:holidays] = holidays
      week
    end

    # Calculate member's timers that are overtime
    def member_overtime(member)
      weeks = {} # Include information of weeks - working_time, overtime and holidays
      timers = [] # Overtime timers
      normal_timers = [] # Include the normal timers (not weekend or holiday)
      overtime_timers(member).each do |timer|
        week_date = timer.start_time.to_date # Get date of timer
        week_start_date = week_start_date(week_date, @begin_week) # A week is identified by the first day of week
        weeks[week_start_date] = week_info(week_start_date, member) if weeks[week_start_date].blank? # Create info for new week

        # If week has no overtime, then skip
        next unless weeks[week_start_date][:overtime] > 0
        options = {}
        if weeks[week_start_date][:holidays].include?(week_date) # Overtime in holidays
          options[:overtime_type] = @overtime_type[:holiday]
          if weeks[week_start_date][:overtime] - timer.tracked_time < 0 # Leftover overtime less than period time of timer
            options[:stop_time_overtime] = timer.start_time + weeks[week_start_date][:overtime] # Adjust the stop_time of timer
            weeks[week_start_date][:overtime] = 0 # Because there is no overtime left over
          else
            weeks[week_start_date][:overtime] -= timer.tracked_time
          end
        elsif week_date.wday == 0 || week_date.wday == 6 # Overtime in weekend
          options[:overtime_type] = @overtime_type[:weekend]
          if weeks[week_start_date][:overtime] - timer.tracked_time < 0 # Leftover overtime less than period time of timer
            options[:stop_time_overtime] = timer.start_time + weeks[week_start_date][:overtime] # Adjust the stop_time of timer
            weeks[week_start_date][:overtime] = 0 # Because there is no overtime left over
          else
            weeks[week_start_date][:overtime] -= timer.tracked_time
          end
        else # If week_date is a normal day
          normal_timers.push(timer) # classify timers in not special days to process later
        end
        # Serialize the timer that overtime
        timers.push(TimerSerializer.new(timer, options).as_json) if options[:overtime_type].present?
      end

      # Calculate overtime for normal days
      day_time_totals = {}
      normal_timers.each do |timer|
        week_date = timer.start_time.to_date
        week_start_date = week_start_date(week_date, @begin_week)

        day_time_totals[week_date] = 0 if day_time_totals[week_date].nil?
        day_time_totals[week_date] += timer.tracked_time
        day_overtime = day_time_totals[week_date] - @working_time_per_day * 3600
        options = {}
        if weeks[week_start_date][:overtime] > 0 && day_overtime > 0
          options[:overtime_type] = @overtime_type[:normal]
          if (day_time_totals[week_date] - timer.tracked_time) < @working_time_per_day * 3600
            options[:start_time_overtime] = timer.stop_time - day_overtime
            if weeks[week_start_date][:overtime] - day_overtime < 0 # Leftover overtime less than period time of adjusted timer
              options[:stop_time_overtime] = options[:start_time_overtime] + weeks[week_start_date][:overtime] # Adjust the stop_time of timer
              weeks[week_start_date][:overtime] = 0 # Because there is no overtime left over
            else
              weeks[week_start_date][:overtime] -= day_overtime
            end
          else
            if weeks[week_start_date][:overtime] - timer.tracked_time < 0 # Leftover overtime less than period time of adjusted timer
              options[:stop_time_overtime] = timer.start_time + weeks[week_start_date][:overtime] # Adjust the stop_time of timer
              weeks[week_start_date][:overtime] = 0 # Because there is no overtime left over
            else
              weeks[week_start_date][:overtime] -= timer.tracked_time
            end
          end
        end

        timers.push(TimerSerializer.new(timer, options).as_json) if options[:overtime_type].present?
      end
      # Return result order by start_time asc
      timers.sort_by! { |hsh| hsh[:start_time] }
    end # End of member_overtime function

    # ===================== GET TIMER ===================
    def overtime_timers(member)
      member.timers
            .where(category_members: { id: member_joined_categories(member).ids })
            .where('start_time >= ? AND start_time < ?', @begin_date, @end_date + 1)
            .order(:start_time)
    end

    def member_joined_categories(member)
      if @reporter.member? && @reporter.id == member.id
        reporter_projects = @reporter.joined_unarchived_projects
      else
        reporter_projects = @reporter.get_projects
      end
      member.assigned_categories.where(projects: { id: reporter_projects.ids })
    end
    # ==================== GET TIMER END ================

    def member_timer(member)
      timers = @member.get_perfect_timers(@begin_date, @end_date)
      ActiveModelSerializers::SerializableResource.new(timers, each_serializer: TimerSerializer)
    end
    # =================== Report by Member helper methods ends =================

    def week_working_time(week_start_date, member)
      member.tracked_time(week_start_date, week_start_date + 6)
    end
  end
end
