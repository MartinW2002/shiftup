Feature: Notice after being promoted from a waiting list
  As a volunteer on a waiting list
  I want to be told when a place opens up for me
  So that I know I am now expected at the shift

  Background:
    Given the organization "Green Campus Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"
    And "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1
    And "Victor" was confirmed for the "09:00" shift of "Lake Clean-up"
    And "Wendy" is waiting for the "09:00" shift of "Lake Clean-up"

  Scenario: The promoted volunteer is told the next time they log in, once
    Given "Victor" cancels the "09:00" shift of "Lake Clean-up"
    And I am "Wendy"
    And I am logged in
    Then I should see "Good news! A place opened up, so you are now confirmed for Lake Clean-up on"
    When I go to my shifts
    Then I should not see "Good news!"

  Scenario: A volunteer who is already logged in sees it on their next page
    Given I am "Wendy"
    And I am logged in
    And "Victor" cancels the "09:00" shift of "Lake Clean-up"
    When I go to my shifts
    Then I should see "Good news! A place opened up, so you are now confirmed for Lake Clean-up on"

  Scenario: Volunteers who were not promoted see no notice
    Given "Victor" cancels the "09:00" shift of "Lake Clean-up"
    And I am "Victor"
    And I am logged in
    Then I should not see "Good news!"
