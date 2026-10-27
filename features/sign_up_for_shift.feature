Feature: Sign up for a shift (US1)
  As a volunteer
  I want to sign up for a shift
  So that I can help at an activity

  Background:
    Given the organization "Green Campus Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"
    And I am a volunteer of "Green Campus Society"
    And I am logged in

  Scenario: Signing up for a shift with free capacity confirms me
    Given "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 2
    When I go to the page for the activity "Lake Clean-up"
    And I press "Sign up"
    Then I should see "You are signed up for this shift."
    And I should be confirmed for the "09:00" shift of "Lake Clean-up"

  Scenario: Signing up for a full shift puts me on the waiting list with my position
    Given "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1
    And the "09:00" shift of "Lake Clean-up" is full
    And 1 other volunteer is waiting for the "09:00" shift of "Lake Clean-up"
    When I go to the page for the activity "Lake Clean-up"
    And I press "Join waiting list"
    Then I should see "This shift is full. You are number 2 on the waiting list."
    And I should see "Waiting list #2"

  Scenario: Signing up for a shift that overlaps my confirmed shift is refused
    Given "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 2
    And "Lake Clean-up" has a shift tomorrow from "10:00" to "12:00" with capacity 2
    And I am confirmed for the "09:00" shift of "Lake Clean-up"
    When I go to the page for the activity "Lake Clean-up"
    And I press "Sign up"
    Then I should see "This shift overlaps your confirmed shift for Lake Clean-up"
    And I should not be signed up for the "10:00" shift of "Lake Clean-up"

  Scenario: My shifts lists my sign-ups and waiting list positions
    Given "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1
    And "Lake Clean-up" has a shift tomorrow from "13:00" to "15:00" with capacity 1
    And I am confirmed for the "09:00" shift of "Lake Clean-up"
    And the "13:00" shift of "Lake Clean-up" is full
    And I am waiting for the "13:00" shift of "Lake Clean-up"
    When I go to my shifts
    Then I should see "Confirmed"
    And I should see "Waiting list #1"

  Scenario: Shifts of an organization I do not belong to cannot be signed up for
    Given the organization "Harbour Tutoring Club" exists
    And "Harbour Tutoring Club" has the activity "Weekend Maths Tutoring"
    And "Weekend Maths Tutoring" has a shift tomorrow from "09:00" to "11:00" with capacity 2
    When I try to sign up for the "09:00" shift of "Weekend Maths Tutoring" directly
    Then I should see "Join this organization before signing up for its shifts."
