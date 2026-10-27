# ShiftUp

Volunteer coordination for student organizations. Organizations publish activities and shifts,
volunteers sign up within capacity, and cancellations are refilled from an ordered waiting list.

> Course demonstration project for CSCI3100 (Option E: CUHK volunteer coordination).
> Not an official CUHK service. All organizations, people and events are fictional.

- **Members:** Olha Mudryk, Martin Wiesner
- **Deployed URL:** https://shiftup.onrender.com
- **CI run for the submitted version:** _TODO: link to the GitHub Actions run_

## Features

| Status | Feature |
| --- | --- |
| Done | Accounts (Devise): sign up, log in, log out |
| Done | Organizations with per-organization roles (volunteer, organizer) |
| Done | Join any organization as a volunteer from the organizations page (organizer roles are never self-assigned) |
| Done | Organization isolation: only members see an organization's activities; direct URLs are denied |
| Done | Organizers create, edit and delete their organization's activities and shifts |
| Done | US1: sign up for a shift (capacity, waiting list with position, overlap check) |
| Done | US2: cancel a sign-up or leave a waiting list; the next eligible volunteer is promoted |
| Done | US3: organizers record attendance (present / absent) for confirmed volunteers |
| Done | Find shifts: search by text and filter by organization, date range and free places |
| Done | My shifts: upcoming shifts with waiting list positions, and past shifts with attendance |
| Done | Organizers see each shift's confirmed volunteers and waiting list in order |

## Roles and business rules

- **Volunteer:** signs up for shifts, joins waiting lists, cancels and views their own schedule.
- **Organizer:** manages activities, shifts, capacity and attendance for their own organization.
- Roles are granted per organization (`memberships.role`), so a user can organize one society and volunteer for another.

| Rule | Description |
| --- | --- |
| Capacity | Confirmed sign-ups never exceed a shift's capacity, even under concurrent requests. Signing up for a full shift joins its waiting list. An organizer cannot lower the capacity below the volunteers already confirmed. |
| No overlap | A volunteer cannot hold two confirmed shifts that overlap in time, across all organizations. A sign-up (or waiting list entry) that overlaps a confirmed shift is refused with the clashing shift named. Shifts that touch (one ends when the next starts) do not overlap. |
| Waiting list | First come, first served by join time (`signups.created_at`, ties broken by `id`). A volunteer has at most one active sign-up per shift and sees their position. |
| Shift changes | Shifts must start in the future and end after they start. Their times cannot change once volunteers have signed up, and shifts or activities with sign-ups cannot be deleted. Shifts that have started accept no sign-ups. |
| Promotion | When a place opens (a cancellation, or an organizer raising the capacity), the earliest waitlisted volunteer without an overlapping confirmed shift is confirmed. A skipped volunteer keeps their place in line. Places owed to the waiting list are filled before a newcomer's sign-up is handled, so nobody can jump the queue. |
| Cancellation | Volunteers cancel only their own sign-ups, and only before the shift starts. The sign-up is kept with status `cancelled` as a record. An account cannot be deleted while it holds upcoming shifts or waiting list places, so those places are passed on first. |
| Attendance | Recorded only for confirmed volunteers, only once the shift has started, and only by the organization's organizers. |
| Authorization | Only the owning organization's organizers can edit activities, shifts or attendance, and only members can see or sign up for an organization's shifts. Enforced on the server with Pundit. |

**Concurrency.** Sign-ups, cancellations and capacity changes go through `ShiftSignup`, `ShiftCancellation`
and `ShiftPromotion` ([app/services/](app/services/)). Each locks the shift row and then the volunteers
involved (`SELECT ... FOR UPDATE`) while it checks the rules and changes sign-ups. Simultaneous requests for
the same shift, or by the same volunteer, therefore run one at a time. Volunteers are always locked in
ascending id order after a single shift, so two requests can wait for each other but never deadlock. The
concurrency tests in `spec/services/shift_signup_spec.rb` fail when the locks are removed or taken in
waiting-list order.

## Runtime versions

- Ruby 3.3.8 (see `.ruby-version`)
- Rails 8.1.4
- PostgreSQL 17 (any version from 14 works)
- Devise 5.0, Pundit 2.5, RSpec Rails 8.0, Cucumber Rails 4.1, SimpleCov 1.3

## Local setup

Prerequisites: Ruby 3.3.8 and a running PostgreSQL server. On Ubuntu or WSL:

```bash
sudo apt install postgresql libpq-dev
sudo service postgresql start
sudo -u postgres createuser --superuser "$USER"
```

Then:

```bash
git clone https://github.com/martinw2002/shiftup.git
cd shiftup
bin/setup --skip-server   # installs gems, creates, migrates and seeds the database
```

If PostgreSQL needs a password or runs elsewhere, set `DATABASE_URL`, for example
`export DATABASE_URL=postgres://user:password@localhost:5432/shiftup_development`.

### Seed demo data

```bash
bin/rails db:seed    # safe to run more than once
bin/rails db:reset   # drop, recreate and reseed
```

### Run

```bash
bin/dev              # http://localhost:3000
```

## Demo accounts

All demo accounts use the password `password123`.

| Email | Role |
| --- | --- |
| organizer.green@example.com | Organizer of Green Campus Society |
| organizer.harbour@example.com | Organizer of Harbour Tutoring Club |
| volunteer1@example.com | Volunteer in both organizations |
| volunteer2@example.com | Volunteer in Green Campus Society |
| volunteer3@example.com | Volunteer in Green Campus Society |

Demo walkthrough with the seeded data:

- **Confirmed sign-up:** `volunteer1` is already confirmed for the first "Lake Clean-up" shift (see *My shifts*).
  Any volunteer can sign up for the second Lake Clean-up shift, which has free places.
- **Waiting list:** the "Recycling Drive" shift is full (`volunteer2` and `volunteer3`). `volunteer1` pressing
  *Join waiting list* gets position 1.
- **Overlap refused:** `volunteer1` signing up for the first "Weekend Maths Tutoring" shift (Harbour Tutoring Club)
  is refused, because it overlaps their confirmed Lake Clean-up shift.
- **Cancel and promote:** after `volunteer1` joins the Recycling Drive waiting list, `volunteer2` pressing
  *Cancel sign-up* (on *My shifts*) confirms `volunteer1` automatically.
- **Attendance:** `organizer.green` opens the past "Tree Planting" shift and marks volunteers *Present* or *Absent*.
  Volunteers see the result under *Past shifts* on *My shifts*.
- **Search:** *Find shifts* searches the upcoming shifts of the user's organizations by text, organization,
  dates and free places.
- **Access restriction:** `organizer.green` opening a Harbour Tutoring Club shift's edit URL is refused, as is
  `organizer.harbour` trying to change Tree Planting attendance.

## Tests

```bash
bundle exec rspec       # unit, policy and request specs (spec/)
bundle exec cucumber    # acceptance tests (features/)
bin/ci                  # everything CI runs: style, security scans and both test suites
```

### Coverage

Coverage is measured with SimpleCov (line and branch coverage of `app/` and `lib/`). RSpec and
Cucumber results are merged into one report at `coverage/index.html`. To reproduce:

```bash
rm -rf coverage
bundle exec rspec
COVERAGE_CHECK=1 bundle exec cucumber   # fails if merged line coverage is below 80%
```

Current coverage: _TODO: fill in for the submitted version_.

## Continuous integration

GitHub Actions (`.github/workflows/ci.yml`) runs on every push and pull request:
Brakeman, bundler-audit, importmap audit, RuboCop, RSpec and Cucumber against PostgreSQL. The
coverage report is uploaded as a build artifact.

## Deployment

Hosted on Render (web service, `render.yaml`) with the database on Neon PostgreSQL.
`bin/render-build.sh` installs gems, precompiles assets, runs migrations and seeds the demo data.
Required environment variables: `DATABASE_URL` (Neon connection string) and `SECRET_KEY_BASE`
(generated by Render).

## TDD/BDD iteration

_TODO: describe one iteration, e.g. US2 promotion: the Cucumber scenario written first, the failing
RSpec examples, the implementation, and the refactoring that followed._

## Known limitations

- No password reset. The demo deployment does not send email, so Devise's password recovery is turned off.
- Demo shifts are dated relative to the day the seeds run (the coming Saturday). Each deploy runs the seeds,
  which add a fresh set of shifts to an activity only once all of its demo shifts are in the past.
- Volunteers are not notified when they are promoted from a waiting list; they see it on *My shifts*.
- Organizers cannot remove a volunteer from a shift; volunteers cancel their own sign-ups.
- _TODO_

## Acknowledgements

- Claude Code has been used to generator code for this project using model Opus 5.5.
- Built on Ruby on Rails and the libraries listed in the `Gemfile`, notably Devise (authentication),
  Pundit (authorization), RSpec, Cucumber, Capybara, FactoryBot, Shoulda Matchers and SimpleCov.
- Application skeleton generated with `rails new`; Devise views generated with `rails generate devise:views`.