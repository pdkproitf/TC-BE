module ReportApi
  class Reports < Grape::API
    prefix :api
    version 'v1', using: :accept_version_header
    helpers ReportHelper
    helpers do
      def validate_date(begin_date, end_date)
        error!(I18n.t('begin_date_not_greater_than_end_day'), 400) if begin_date > end_date
        error!(I18n.t('day_limit'), 400) if (end_date - begin_date).to_i > 366
      end
    end

    resource :reports do
      # => /api/v1/reports/
      before do
        authenticated!
        validate_date(params[:begin_date], params[:end_date])
      end

      desc 'Report by time'
      params do
        requires :begin_date, type: Date, desc: 'Begin date'
        requires :end_date, type: Date, desc: 'End date'
      end
      get 'time' do
        report = ReportHelper::Report.new(@current_member, params[:begin_date], params[:end_date])
        { data: report.report_by_time }
      end

      desc 'Report by projects'
      params do
        requires :begin_date, type: Date, desc: 'Begin date'
        requires :end_date, type: Date, desc: 'End date'
      end
      get 'project' do
        projects = @current_member.company.projects.where(is_archived: false)
        # If member is not pm of any project then access denied
        if @current_member.member? &&
           @current_member.project_members.where(project_id: projects.ids, is_pm: true, is_archived: false).empty?
          return error!(I18n.t('access_denied'), 403)
        end
        report = ReportHelper::Report.new(@current_member, params[:begin_date], params[:end_date])
        { data: report.report_by_project }
      end

      desc 'Report by member'
      params do
        requires :begin_date, type: Date, desc: 'Begin date'
        requires :end_date, type: Date, desc: 'End date'
        requires :member_id, type: Integer, desc: 'Member ID'
      end
      get 'member' do
        member = @current_member.company.members.find(params[:member_id])
        # Only Admin can run report of himself. Staff cannot run report of super PM
        if (member.admin? && !@current_member.admin?) || (member.pm? && @current_member.member?)
          return error!(I18n.t('access_denied'), 403)
        end

        if member.member? && member.id != @current_member.id
          # IDs of projects that current_member is pm
          project_ids = @current_member.pm_projects.where(is_archived: false).ids
          is_member_joined_projects = member.project_members.exists?(project_id: project_ids, is_archived: false)
          return error!(I18n.t('access_denied'), 403) if is_member_joined_projects == false
        end

        report = ReportHelper::Report.new(@current_member, params[:begin_date], params[:end_date], member: member)
        { data: report.report_by_member }
      end
    end
  end
end
