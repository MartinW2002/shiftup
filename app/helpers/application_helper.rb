module ApplicationHelper
  # Header link, highlighted while the user is anywhere in that section.
  def nav_link(name, path)
    active = request.path == path || request.path.start_with?("#{path}/")
    link_to name, path, class: [ "nav-link", ("active" if active) ], aria: { current: ("page" if active) }
  end
end
