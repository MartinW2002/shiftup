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
| Planned | Activities and shifts managed by organizers |
| Planned | US1: sign up for a shift (capacity, waiting list, overlap check) |
| Planned | US2: cancel and promote the next eligible volunteer |
| Planned | US3: organizers record attendance |
| Planned | Search and filter shifts |

## Roles and business rules

- **Volunteer:** signs up for shifts, joins waiting lists, cancels and views their own schedule.
- **Organizer:** manages activities, shifts, capacity and attendance for their own organization.
- Roles are granted per organization (`memberships.role`), so a user can organize one society and volunteer for another.

| Rule | Description |
| --- | --- |
| Capacity | Confirmed sign-ups never exceed a shift's capacity, even under concurrent requests. |
| No overlap | A volunteer cannot hold two confirmed shifts that overlap in time. Shifts that touch (one ends when the next starts) do not overlap. |
| Waiting list | First come, first served by join time (`signups.created_at`, ties broken by `id`). A volunteer has at most one active sign-up per shift. |
| Promotion | A cancellation confirms the earliest waitlisted volunteer who has no overlapping confirmed shift. |
| Authorization | Only the owning organization's organizers can edit shifts or attendance. Enforced on the server with Pundit. |

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

The seeded "Lake Clean-up" (Green Campus Society) and "Weekend Maths Tutoring" (Harbour Tutoring Club)
shifts overlap on purpose, so the overlap rule can be shown with `volunteer1`.

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
- _TODO_

## Acknowledgements

- Claude Code has been used to generator code for this project using model Opus 5.5.
- Built on Ruby on Rails and the libraries listed in the `Gemfile`, notably Devise (authentication),
  Pundit (authorization), RSpec, Cucumber, Capybara, FactoryBot, Shoulda Matchers and SimpleCov.
- Application skeleton generated with `rails new`; Devise views generated with `rails generate devise:views`.