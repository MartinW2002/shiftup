# ShiftUp

[![CI](https://github.com/MartinW2002/shiftup/actions/workflows/ci.yml/badge.svg)](https://github.com/MartinW2002/shiftup/actions/workflows/ci.yml)

Volunteer coordination for student organizations. Organizations publish activities and shifts,
volunteers sign up within capacity, and cancellations are refilled from an ordered waiting list.

> Course demonstration project for CSCI3100 (Option E: CUHK volunteer coordination).
> Not an official CUHK service. All organizations, people and events are fictional.

- **Members:** Olha Mudryk, Martin Wiesner
- **Topic:** Option E, CUHK volunteer coordination
- **Deployed URL:** https://shiftup.onrender.com (free Render instance: the first request after a quiet period can take about a minute)
- **CI run for the submitted version:** _TODO at submission: link the GitHub Actions run of the graded commit_.
  All runs: https://github.com/MartinW2002/shiftup/actions/workflows/ci.yml

## Features

**Volunteers**

- Join any organization as a volunteer (organizer roles are never self-assigned)
- Sign up for a shift within capacity, or join its waiting list and see your position; overlapping shifts are refused (US1)
- Cancel a sign-up or leave a waiting list; the next eligible volunteer is promoted (US2)
- Find shifts by text, organization, date range and free places
- *My shifts*: upcoming shifts with waiting list positions, and past shifts with attendance

**Organizers** (for their own organization only)

- Create, edit and delete activities and shifts
- See each shift's confirmed volunteers and waiting list in order
- Record attendance (present / absent) for confirmed volunteers (US3)

**Everyone**

- Accounts (Devise): sign up, log in, log out, edit your details
- Roles are granted per organization, and an organization's records are visible only to its members,
  including through direct URLs

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

Current coverage (commit `2ad0280`): **100% of lines (472/472) and 100% of branches (131/131)**, from
223 RSpec examples and 31 Cucumber scenarios. Each CI run uploads the HTML report as the `coverage` artifact.

What the suites cover:

| Area | Where |
| --- | --- |
| Core stories US1–US3 | `features/sign_up_for_shift.feature`, `features/cancel_and_promote.feature`, `features/manage_attendance.feature` |
| Business-rule failures (full shift, overlap, duplicates, started shifts, capacity, attendance) | `spec/services/`, `spec/models/` |
| Concurrency (capacity, overlap, deadlocks) | `spec/services/shift_signup_spec.rb` ("under concurrent requests") |
| Permissions, including direct URLs | `spec/policies/`, `spec/requests/`, `features/manage_shifts.feature` |
| Organization isolation | `features/organization_access.feature`, `spec/requests/organizations_spec.rb`, `spec/policies/shift_policy_spec.rb` |
| Search and filters | `features/find_shifts.feature`, `spec/queries/shift_search_spec.rb` |
| Demo data | `spec/seeds_spec.rb` |

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

Example: the capacity rule of **US1** ("confirmed sign-ups never exceed capacity, even under concurrent
requests"), and how **US2** forced a second iteration on it.

1. **Acceptance first (BDD).** The US1 acceptance criteria were written as the scenarios in
   `features/sign_up_for_shift.feature` (free place → confirmed; full shift → waiting list with position;
   overlap → refused) before `ShiftSignup` and its pages existed.
2. **Unit level (TDD).** `spec/services/shift_signup_spec.rb` describes each rule and refusal message.
   Sequential examples cannot show the "concurrent requests" part of the rule, so the example "never
   confirms more volunteers than the capacity" runs four sign-ups for a one-place shift in parallel threads,
   pausing each request between the capacity check and the insert so that a race shows up reliably.
3. **Red and green.** Without row locks this example fails with *expected 1, got 4* confirmed volunteers,
   and the overlap example (one volunteer, two overlapping shifts at once) with *expected 1, got 2*.
   `ShiftSignup` locks the shift and the volunteer (`SELECT ... FOR UPDATE`) for the whole check-and-insert,
   which makes both pass (commit `37e3568`).
4. **Next iteration (US2).** Promotion locks several waiting volunteers at once. A new example lets two
   cancellations promote the same two volunteers in opposite waiting-list order; locking them one at a time
   in waiting-list order makes it fail with PostgreSQL's *deadlock detected*. The fix (one shift, then
   volunteers in ascending id order) moved the locking into `ShiftPromotion`, which sign-ups, cancellations
   and capacity changes now share. The US2 scenarios in `features/cancel_and_promote.feature` were added,
   and the US1 scenarios and examples stayed green (commit `a282a1b`).

## Known limitations

- No password reset. The demo deployment does not send email, so Devise's password recovery is turned off.
- Demo shifts are dated relative to the day the seeds run (the coming Saturday). Each deploy runs the seeds,
  which add a fresh set of shifts to an activity only once all of its demo shifts are in the past.
- Volunteers are not notified when they are promoted from a waiting list; they see it on *My shifts*.
- Organizers cannot remove a volunteer from a shift; volunteers cancel their own sign-ups.
- There is no page for creating organizations or granting the organizer role. Both come from the seeds
  (or the Rails console); new accounts join organizations as volunteers.
- Members cannot leave an organization, and an organizer who deletes their account can leave an
  organization without organizers.
- Deleting an account also deletes that user's past attendance records.
- Times are entered and shown in Hong Kong time only. *Find shifts* has no pagination.

## Acknowledgements

- Claude Code has been used to generate code for this project using model Opus 5.5.
- Built on Ruby on Rails and the libraries listed in the `Gemfile`, notably Devise (authentication),
  Pundit (authorization), RSpec, Cucumber, Capybara, FactoryBot, Shoulda Matchers and SimpleCov.
- Application skeleton generated with `rails new`; Devise views generated with `rails generate devise:views`.