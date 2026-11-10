Feature: Leave an organization
  As a volunteer
  I want to leave an organization I no longer help
  So that its activities no longer appear in my lists

  Background:
    Given the organization "Green Campus Society" exists
    And "Green Campus Society" has the activity "Lake Clean-up"

  Scenario: A volunteer leaves an organization
    Given I am a volunteer of "Green Campus Society"
    And I am logged in
    When I visit the page for "Green Campus Society"
    And I press "Leave organization"
    Then I should see "You left Green Campus Society."
    And "Green Campus Society" should be listed under "Other organizations"
    When I visit the page for "Green Campus Society"
    Then I should see "Only members can see this organization's activities."

  Scenario: Leaving cancels my upcoming shifts and waiting list places there
    Given I am a volunteer of "Green Campus Society"
    And "Lake Clean-up" has a shift tomorrow from "09:00" to "11:00" with capacity 1
    And "Lake Clean-up" has a shift tomorrow from "13:00" to "15:00" with capacity 1
    And I am confirmed for the "09:00" shift of "Lake Clean-up"
    And "Wendy" is waiting for the "09:00" shift of "Lake Clean-up"
    And the "13:00" shift of "Lake Clean-up" is full
    And I am waiting for the "13:00" shift of "Lake Clean-up"
    And I am logged in
    When I visit the page for "Green Campus Society"
    Then the leave confirmation should say "Your 1 upcoming shift and 1 waiting list place there will be cancelled."
    When I press "Leave organization"
    Then I should see "You left Green Campus Society. Your 1 upcoming shift and 1 waiting list place there were cancelled."
    And I should not be signed up for the "09:00" shift of "Lake Clean-up"
    And I should not be signed up for the "13:00" shift of "Lake Clean-up"
    And "Wendy" should be confirmed for the "09:00" shift of "Lake Clean-up"

  Scenario: Leaving keeps my past shifts and attendance
    Given I am a volunteer of "Green Campus Society"
    And "Lake Clean-up" had a shift yesterday from "09:00" to "11:00"
    And I was confirmed and present for the "09:00" shift of "Lake Clean-up"
    And I am logged in
    When I visit the page for "Green Campus Society"
    Then the leave confirmation should say "Leave Green Campus Society? You can join again later."
    When I press "Leave organization"
    And I go to my shifts
    Then I should see "Past shifts"
    And I should see "Present"

  Scenario: Organizers do not get the option to leave
    Given I am an organizer of "Green Campus Society"
    And I am logged in
    When I visit the page for "Green Campus Society"
    Then I should not see "Leave organization"

  Scenario: An organizer cannot leave through a direct request
    Given I am an organizer of "Green Campus Society"
    And I am logged in
    When I try to leave "Green Campus Society" directly
    Then I should see "Organizers cannot leave their organization."
    And I should still be an organizer of "Green Campus Society"
