Feature: Manage attendance (US3)
  As an organizer
  I want to record attendance
  So that my organization keeps accurate records

  Background:
    Given the organization "Green Campus Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"
    And "Lake Clean-up" had a shift yesterday from "09:00" to "11:00"
    And "Vera" was confirmed for the "09:00" shift of "Lake Clean-up"

  Scenario: Recording that a volunteer attended
    Given I am an organizer of "Green Campus Society"
    And I am logged in
    When I go to the "09:00" shift of "Lake Clean-up"
    And I mark "Vera" as "Present"
    Then I should see "Attendance saved: Vera Volunteer was present."
    And "Vera" should be recorded as present for the "09:00" shift of "Lake Clean-up"

  Scenario: An organizer of another organization cannot change attendance via a URL
    Given the organization "Harbour Tutoring Club" exists
    And I am an organizer of "Harbour Tutoring Club"
    And I am logged in
    When I try to mark "Vera" as present for the "09:00" shift of "Lake Clean-up" directly
    Then I should see "Only this organization's organizers can record attendance."
    And "Vera" should be recorded as unmarked for the "09:00" shift of "Lake Clean-up"

  Scenario: Volunteers see their attendance in their shift history
    Given I am "Vera"
    And I am logged in
    And "Vera" was recorded as present for the "09:00" shift of "Lake Clean-up"
    When I go to my shifts
    Then I should see "Past shifts"
    And I should see "Present"
