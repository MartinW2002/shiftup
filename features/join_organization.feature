Feature: Join an organization
  As a volunteer
  I want to join a student organization
  So that I can see its activities and sign up for shifts

  Background:
    Given the organization "Green Campus Society" exists
    And the organization "Harbour Tutoring Club" exists
    And I am logged in

  Scenario: Joining an organization as a volunteer
    When I go to the organizations page
    And I join "Harbour Tutoring Club"
    Then I should see "You joined Harbour Tutoring Club as a volunteer."
    And I should be a volunteer of "Harbour Tutoring Club"

  Scenario: An organization I joined moves to my list
    Given I am a volunteer of "Green Campus Society"
    When I go to the organizations page
    Then "Green Campus Society" should be listed under "Your organizations"
    And there should be no join button for "Green Campus Society"
