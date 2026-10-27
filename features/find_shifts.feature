Feature: Find shifts
  As a volunteer
  I want to search and filter upcoming shifts
  So that I can quickly find one that suits me

  Background:
    Given the organization "Green Campus Society" exists
    And the organization "Harbour Tutoring Club" exists
    And the organization "Drama Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"
    And "Green Campus Society" has the activity "Recycling Drive"
    And "Harbour Tutoring Club" has the activity "Weekend Maths Tutoring"
    And "Drama Society" has the activity "Stage Building"
    And "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1
    And "Recycling Drive" has a shift tomorrow from "13:00" to "15:00" with capacity 2
    And "Weekend Maths Tutoring" has a shift tomorrow from "10:00" to "12:00" with capacity 2
    And "Stage Building" has a shift tomorrow from "14:00" to "16:00" with capacity 2
    And the "09:00" shift of "Lake Clean-up" is full
    And I am a volunteer of "Green Campus Society"
    And I am a volunteer of "Harbour Tutoring Club"
    And I am logged in

  Scenario: Shifts from all my organizations are listed, and only those
    When I go to find shifts
    Then I should see "Lake Clean-up"
    And I should see "Weekend Maths Tutoring"
    And I should not see "Stage Building"

  Scenario: Searching by text
    When I go to find shifts
    And I fill in "Search" with "tutoring"
    And I press "Search"
    Then I should see "1 shift found"
    And I should see "Weekend Maths Tutoring"
    And I should not see "Lake Clean-up"

  Scenario: Filtering by organization and free places
    When I go to find shifts
    And I select "Green Campus Society" from "Organization"
    And I check "Only shifts with free places"
    And I press "Search"
    Then I should see "Recycling Drive"
    And I should not see "Lake Clean-up"
    And I should not see "Weekend Maths Tutoring"
