Feature: Remove a volunteer from a shift
  As an organizer
  I want to remove someone from a shift
  So that the shift is staffed by the right people

  Background:
    Given the organization "Green Campus Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"
    And "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1
    And "Victor" was confirmed for the "09:00" shift of "Lake Clean-up"
    And "Wendy" is waiting for the "09:00" shift of "Lake Clean-up"

  Scenario: An organizer removes a confirmed volunteer, and the next in line gets the place
    Given I am an organizer of "Green Campus Society"
    And I am logged in
    When I go to the "09:00" shift of "Lake Clean-up"
    Then the remove confirmation for "Victor" should say "Remove Victor Volunteer from this shift? They will be told the next time they open ShiftUp. The first eligible person on the waiting list gets the place."
    When I remove "Victor" from the shift
    Then I should see "Victor Volunteer was removed from this shift. Wendy Volunteer moved up from the waiting list."
    And "Victor" should no longer be signed up for the "09:00" shift of "Lake Clean-up"
    And "Wendy" should be confirmed for the "09:00" shift of "Lake Clean-up"

  Scenario: The removed volunteer is told once, the next time they log in
    Given an organizer of "Green Campus Society" removed "Victor" from the "09:00" shift of "Lake Clean-up"
    And I am "Victor"
    And I am logged in
    Then I should see "An organizer of Green Campus Society removed you from Lake Clean-up on"
    When I go to my shifts
    Then I should not see "removed you from"

  Scenario: An organizer removes someone from the waiting list
    Given I am an organizer of "Green Campus Society"
    And I am logged in
    When I go to the "09:00" shift of "Lake Clean-up"
    And I remove "Wendy" from the shift
    Then I should see "Wendy Volunteer was removed from the waiting list."
    And "Wendy" should no longer be signed up for the "09:00" shift of "Lake Clean-up"
    And "Victor" should be confirmed for the "09:00" shift of "Lake Clean-up"

  Scenario: An organizer of another organization cannot remove volunteers via a URL
    Given the organization "Harbour Tutoring Club" exists
    And I am an organizer of "Harbour Tutoring Club"
    And I am logged in
    When I try to remove "Victor" from the "09:00" shift of "Lake Clean-up" directly
    Then I should see "Only this organization's organizers can remove volunteers from a shift."
    And "Victor" should be confirmed for the "09:00" shift of "Lake Clean-up"
