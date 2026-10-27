class ShiftPolicy < ActivityPolicy
  private

  def organization
    record.activity.organization
  end
end
