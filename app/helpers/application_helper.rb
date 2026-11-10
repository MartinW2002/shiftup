module ApplicationHelper
  # Header link, highlighted while the user is anywhere in that section.
  def nav_link(name, path)
    active = request.path == path || request.path.start_with?("#{path}/")
    link_to name, path, class: [ "nav-link", ("active" if active) ], aria: { current: ("page" if active) }
  end

  # The one message style used across the app: flash messages, form errors and search errors.
  # +kind+ is :error (red, "!") or :success (green, "✓"). Pass the text, or a block for richer content.
  def message_box(kind, text = nil, extra_class: nil, &block)
    error = kind.to_sym == :error
    tag.div(class: [ "message", "message-#{error ? 'error' : 'success'}", extra_class ],
            role: error ? "alert" : "status") do
      tag.span(error ? "!" : "✓", class: "message-icon", aria: { hidden: true }) +
        tag.div(block ? capture(&block) : text, class: "message-body")
    end
  end

  # Devise and the controllers use :alert for problems and :notice for confirmations.
  def flash_kind(type)
    type.to_s == "alert" ? :error : :success
  end
end
