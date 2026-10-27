Feature: Cancel and promote (US2)
  As a volunteer
  I want to cancel my sign-up
  So that someone else can take my place

  Background:
    Given the organization "Green Campus Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"
    And I am a volunteer of "Green Campus Society"
    And I am logged in
    And "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1

  Scenario: Cancelling a full shift confirms the first volunteer on the waiting list
    Given I am confirmed for the "09:00" shift of "Lake Clean-up"
    And "Wendy" is waiting for the "09:00" shift of "Lake Clean-up"
    And "Victor" is waiting for the "09:00" shift of "Lake Clean-up"
    When I go to the page for the activity "Lake Clean-up"
    And I press "Cancel sign-up"
    Then I should see "Your sign-up was cancelled. The next volunteer on the waiting list has been confirmed."
    And "Wendy" should be confirmed for the "09:00" shift of "Lake Clean-up"
    And "Victor" should be number 1 on the waiting list for the "09:00" shift of "Lake Clean-up"

  Scenario: The first in line has an overlapping shift, so the next eligible volunteer is confirmed
    Given I am confirmed for the "09:00" shift of "Lake Clean-up"
    And "Wendy" is waiting for the "09:00" shift of "Lake Clean-up"
    And "Victor" is waiting for the "09:00" shift of "Lake Clean-up"
    And "Wendy" is confirmed for another shift tomorrow from "10:00" to "12:00"
    When I go to the page for the activity "Lake Clean-up"
    And I press "Cancel sign-up"
    Then "Victor" should be confirmed for the "09:00" shift of "Lake Clean-up"
    And "Wendy" should be number 1 on the waiting list for the "09:00" shift of "Lake Clean-up"

  Scenario: Leaving the waiting list
    Given the "09:00" shift of "Lake Clean-up" is full
    And I am waiting for the "09:00" shift of "Lake Clean-up"
    When I go to my shifts
    And I press "Leave waiting list"
    Then I should see "You left the waiting list."
    And I should not be signed up for the "09:00" shift of "Lake Clean-up"

  Scenario: An organizer raising the capacity confirms volunteers from the waiting list
    Given I am an organizer of "Green Campus Society"
    And the "09:00" shift of "Lake Clean-up" is full
    And "Wendy" is waiting for the "09:00" shift of "Lake Clean-up"
    When I go to edit the "09:00" shift of "Lake Clean-up"
    And I fill in "Capacity" with "2"
    And I press "Update Shift"
    Then I should see "Shift updated. 1 volunteer was moved from the waiting list."
    And "Wendy" should be confirmed for the "09:00" shift of "Lake Clean-up"
