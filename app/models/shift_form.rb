# The "Add shift" and "Edit shift" form: a date, a start time and an end time instead of two
# timestamps. An end time earlier than the start time means the shift runs past midnight and
# ends the next day; an end time equal to the start time is rejected.
#
# When adding, the organizer can repeat the shift on more dates picked in a calendar. All shifts
# are created in one transaction: either every date is added or none is.
class ShiftForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAX_DATES = 60
  TIME_FORMAT = /\A([01]\d|2[0-3]):[0-5]\d\z/

  attribute :date, :date
  attribute :start_time, :string
  attribute :end_time, :string
  attribute :capacity, :integer
  attribute :recurring, :boolean, default: false
  attribute :repeat_dates, default: -> { [] }

  validates :date, :start_time, :end_time, :capacity, presence: true
  validate :times_readable_and_different
  validate :dates_not_in_the_past
  validate :not_too_many_dates

  attr_reader :shift, :shifts

  def self.model_name
    ActiveModel::Name.new(self, nil, "Shift")
  end

  # +shift+ is a new shift (built on its activity) or an existing one being edited.
  def initialize(shift:, **attributes)
    @shift = shift
    super(**prefill_from(shift).merge(attributes.compact))
  end

  def persisted?
    shift.persisted?
  end

  def activity
    shift.activity
  end

  # Every date the shift is created on: the main date plus the picked repeat dates.
  def dates
    extra = recurring && shift.new_record? ? Array(repeat_dates).filter_map { |value| parse_date(value) } : []
    ([ date ] + extra).compact.uniq.sort
  end

  def overnight?
    readable_times? && end_time <= start_time
  end

  def starts_at_on(day)
    Time.zone.parse("#{day.iso8601} #{start_time}")
  end

  def ends_at_on(day)
    ends_at = Time.zone.parse("#{day.iso8601} #{end_time}")
    overnight? ? ends_at + 1.day : ends_at
  end

  def save
    return false if invalid?

    shift.new_record? ? create_shifts : update_shift
  end

  private

  def prefill_from(shift)
    return {} if shift.new_record?

    { date: shift.starts_at.to_date, start_time: shift.starts_at.strftime("%H:%M"),
      end_time: shift.ends_at.strftime("%H:%M"), capacity: shift.capacity }
  end

  def create_shifts
    @shifts = dates.map do |day|
      day == dates.first ? shift : activity.shifts.build
    end
    @shifts.zip(dates).each { |record, day| record.assign_attributes(shift_attributes(day)) }

    Shift.transaction do
      @shifts.each do |record|
        next if record.save

        copy_errors(record)
        raise ActiveRecord::Rollback
      end
    end
    errors.empty?
  end

  def update_shift
    shift.assign_attributes(shift_attributes(date))
    return true if shift.save

    copy_errors(shift)
    false
  end

  def shift_attributes(day)
    { starts_at: starts_at_on(day), ends_at: ends_at_on(day), capacity: capacity }
  end

  # Shift validations speak about starts_at / ends_at; on this form they belong to the time fields.
  def copy_errors(record)
    record.errors.each do |error|
      attribute = { starts_at: :start_time, ends_at: :end_time, capacity: :capacity }.fetch(error.attribute, :base)
      attribute == :base ? errors.add(:base, error.full_message) : errors.add(attribute, error.message)
    end
  end

  def times_readable_and_different
    errors.add(:start_time, "must be a time like 09:00") if start_time.present? && !start_time.match?(TIME_FORMAT)
    errors.add(:end_time, "must be a time like 17:00") if end_time.present? && !end_time.match?(TIME_FORMAT)
    errors.add(:end_time, "must be different from the start time") if readable_times? && start_time == end_time
  end

  def dates_not_in_the_past
    return unless shift.new_record? || date != shift.starts_at.to_date

    if date && date < Date.current
      errors.add(:date, "must be today or later")
    elsif date == Date.current && readable_times? && starts_at_on(date) <= Time.current
      errors.add(:start_time, "must be later than now for a shift today")
    end
    errors.add(:base, "Repeat dates must be today or later") if dates.any? { |day| day < Date.current }
  end

  def not_too_many_dates
    errors.add(:base, "A shift can be repeated on at most #{MAX_DATES} dates at once") if dates.size > MAX_DATES
  end

  def readable_times?
    start_time.to_s.match?(TIME_FORMAT) && end_time.to_s.match?(TIME_FORMAT)
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
