Feature: Manage activities and shifts
  As an organizer
  I want to publish activities and their shifts
  So that volunteers can sign up for them

  Background:
    Given the organization "Green Campus Society" exists
    And the organization "Harbour Tutoring Club" exists
    And "Harbour Tutoring Club" has the activity "Weekend Maths Tutoring"

  Scenario: An organizer publishes an activity with a shift
    Given I am an organizer of "Green Campus Society"
    And I am logged in
    When I visit the page for "Green Campus Society"
    And I follow "New activity"
    And I fill in "Title" with "Lake Clean-up"
    And I fill in "Location" with "Weiyuan Lake"
    And I press "Create Activity"
    Then I should see "Activity created."
    When I follow "Add shift"
    And I fill in the shift times for tomorrow from "09:00" to "11:00"
    And I fill in "Capacity" with "3"
    And I press "Create Shift"
    Then I should see "Shift added."
    And I should see "3 of 3 places left"

  Scenario: A shift that ends before it starts is rejected
    Given I am an organizer of "Green Campus Society"
    And "Green Campus Society" has the activity "Lake Clean-up"
    And I am logged in
    When I go to the page for the activity "Lake Clean-up"
    And I follow "Add shift"
    And I fill in the shift times for tomorrow from "11:00" to "09:00"
    And I fill in "Capacity" with "3"
    And I press "Create Shift"
    Then I should see "Ends at must be after the start time"

  Scenario: Volunteers do not see organizer controls
    Given I am a volunteer of "Green Campus Society"
    And "Green Campus Society" has the activity "Lake Clean-up"
    And I am logged in
    When I visit the page for "Green Campus Society"
    Then I should not see "New activity"
    When I go to the page for the activity "Lake Clean-up"
    Then I should not see "Add shift"

  Scenario: An organizer cannot edit another organization's shifts via a direct URL
    Given I am an organizer of "Green Campus Society"
    And "Weekend Maths Tutoring" has a shift tomorrow from "09:00" to "11:00" with capacity 2
    And I am logged in
    When I try to edit the "09:00" shift of "Weekend Maths Tutoring" directly
    Then I should see "Only this organization's organizers can manage its shifts."
