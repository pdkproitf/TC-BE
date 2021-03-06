class Timer < ApplicationRecord
  belongs_to :task

  validate :days_valid

  def tracked_time
    stop_time - start_time
  end

  def approve
    self.is_approved = true unless is_approved
    save!
  end

  def unapprove
    self.is_approved = false if is_approved
    save!
  end

  private

  def days_valid
    errors.add(:start_time, I18n.t('less_than_end_date')) if start_time >= stop_time
  end
end
