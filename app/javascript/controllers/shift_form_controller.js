import { Controller } from "@hotwired/stimulus"

// Pickers and arrow keys move in steps of this many seconds: 00, 15, 30 and 45 minutes.
const QUARTER_HOUR = "900"

// Enhances the shift form (app/views/shifts/_form.html.erb). Without JavaScript the form still
// works: the calendar is a list of checkboxes for each month.
//  - both time pickers always show quarter hours (00, 15, 30, 45); typed times can use any minute.
//    An empty field gets the next quarter hour before its picker opens, because Chrome otherwise
//    opens it at the current time and lists that exact minute.
//  - setting the start time fills an empty end time with one hour later
//  - shows the "ends the next day" hint when the end time is before the start time
//  - shows the repeat calendar only when "Repeat on more dates" is ticked, one month at a time
//  - marks the main date in the calendar, so it cannot be picked twice
//  - summarises how many shifts will be created, and on which dates
export default class extends Controller {
  static targets = ["date", "startTime", "endTime", "overnightHint", "recurring", "calendar",
                    "nav", "title", "previous", "next", "month", "day", "legend", "summary"]

  connect() {
    this.endTimeFilledIn = false // true while the end time is the automatic "start + 1 hour"
    this.timeInputs().forEach((input) => { input.step = QUARTER_HOUR })
    this.timesChanged()
    if (!this.hasCalendarTarget) return

    this.calendarTarget.classList.add("is-enhanced") // month name moves into the navigation bar
    this.navTarget.hidden = false
    this.legendTarget.hidden = false
    this.summaryTarget.hidden = false
    this.monthIndex = Math.max(0, this.monthTargets.findIndex((month) => month.dataset.month === this.mainMonth()))
    this.toggleRecurring()
    this.dateChanged()
  }

  // An empty end time becomes one hour after the start. It keeps following the start time until
  // the organizer sets the end time themselves.
  startTimeChanged() {
    const start = this.startTimeTarget.value
    if (start && (!this.endTimeTarget.value || this.endTimeFilledIn)) {
      this.endTimeTarget.value = this.addMinutes(start, 60)
      this.endTimeFilledIn = true
    }
    this.timesChanged()
  }

  // Runs when an empty time field is clicked or an arrow key is pressed in it, before the picker
  // opens. The end time becomes one hour after the start time (or after the next quarter hour).
  prefillTime(event) {
    const input = event.currentTarget
    if (input.value) return

    if (input === this.startTimeTarget) {
      input.value = this.nextQuarterHour()
      this.startTimeChanged()
    } else {
      input.value = this.addMinutes(this.startTimeTarget.value || this.nextQuarterHour(), 60)
      this.endTimeFilledIn = true
      this.timesChanged()
    }
  }

  endTimeChanged() {
    this.endTimeFilledIn = false
    this.timesChanged()
  }

  timesChanged() {
    const start = this.startTimeTarget.value
    const end = this.endTimeTarget.value
    this.overnightHintTarget.hidden = !(start && end && end < start)
  }

  toggleRecurring() {
    if (!this.hasCalendarTarget) return

    this.calendarTarget.hidden = !this.recurringTarget.checked
    this.showMonth()
    this.updateSummary()
  }

  previousMonth() {
    this.monthIndex = Math.max(0, this.monthIndex - 1)
    this.showMonth()
  }

  nextMonth() {
    this.monthIndex = Math.min(this.monthTargets.length - 1, this.monthIndex + 1)
    this.showMonth()
  }

  dateChanged() {
    if (!this.hasCalendarTarget) return

    const main = this.dateTarget.value
    this.dayTargets.forEach((day) => {
      const isMain = day.value === main
      const label = day.closest(".calendar-day")
      if (label.classList.contains("is-main") && !isMain) {
        day.disabled = false
        day.checked = false
      }
      label.classList.toggle("is-main", isMain)
      if (isMain) {
        day.checked = true
        day.disabled = true // the main date is sent by the Date field; disabled boxes are not submitted
      }
    })
    const index = this.monthTargets.findIndex((month) => month.dataset.month === this.mainMonth())
    if (index >= 0) this.monthIndex = index
    this.showMonth()
    this.updateSummary()
  }

  updateSummary() {
    if (!this.hasCalendarTarget) return

    const main = this.dateTarget.value
    const picked = this.dayTargets.filter((day) => day.checked && !day.disabled).map((day) => day.value)
    const dates = [...new Set([main, ...picked].filter(Boolean))].sort()
    const names = dates.map((date) => this.shortDate(new Date(`${date}T12:00:00`)))

    if (!this.recurringTarget.checked || dates.length < 2) {
      this.summaryTarget.textContent = "Pick one or more dates in the calendar."
    } else {
      this.summaryTarget.textContent = `${dates.length} shifts will be created: ${this.sentence(names)}.`
    }
  }

  // Private

  showMonth() {
    this.monthTargets.forEach((month, index) => { month.hidden = index !== this.monthIndex })
    const current = this.monthTargets[this.monthIndex]
    this.titleTarget.textContent = current.getAttribute("aria-label")
    this.previousTarget.disabled = this.monthIndex === 0
    this.nextTarget.disabled = this.monthIndex === this.monthTargets.length - 1
  }

  // Runs on the submit button's click, which the browser fires before it checks the form (also when
  // Enter is pressed in a field). The quarter-hour step would make it refuse a typed time such as
  // 09:07, so the step is lifted just for that check and put back straight afterwards.
  allowAnyMinute() {
    this.timeInputs().forEach((input) => { input.step = "any" })
    setTimeout(() => this.timeInputs().forEach((input) => { input.step = QUARTER_HOUR }))
  }

  timeInputs() {
    return [this.startTimeTarget, this.endTimeTarget]
  }

  // The current time rounded up to the next quarter hour, for example 14:37 → "14:45".
  nextQuarterHour() {
    const now = new Date()
    const minutes = Math.ceil((now.getHours() * 60 + now.getMinutes() + 1) / 15) * 15
    return this.addMinutes("00:00", minutes)
  }

  // "23:30" + 60 minutes is "00:30": the shift then ends the next day.
  addMinutes(time, minutes) {
    const [hours, mins] = time.split(":").map(Number)
    const total = (hours * 60 + mins + minutes) % (24 * 60)
    return [Math.floor(total / 60), total % 60].map((part) => String(part).padStart(2, "0")).join(":")
  }

  // "Thu 12 Nov", matching how shifts are shown elsewhere in the app.
  shortDate(date) {
    const part = (options) => new Intl.DateTimeFormat("en-GB", options).format(date)
    return `${part({ weekday: "short" })} ${part({ day: "numeric" })} ${part({ month: "short" })}`
  }

  mainMonth() {
    return (this.dateTarget.value || "").slice(0, 7)
  }

  sentence(items) {
    if (items.length <= 2) return items.join(" and ")
    return `${items.slice(0, -1).join(", ")} and ${items[items.length - 1]}`
  }
}
