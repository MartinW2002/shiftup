Feature: Organization access
  As a member of a student organization
  I want to see only the organizations I belong to
  So that each organization's records stay private

  Background:
    Given the organization "Green Campus Society" exists
    And the organization "Harbour Tutoring Club" exists
    And I am a volunteer of "Green Campus Society"
    And I am logged in

  Scenario: Members see their own organization
    When I visit the page for "Green Campus Society"
    Then I should see "Green Campus Society"

  Scenario: Organizations list shows only my memberships
    When I go to the organizations page
    Then I should see "Green Campus Society"
    And I should not see "Harbour Tutoring Club"

  Scenario: Another organization's page is denied via a direct URL
    When I visit the page for "Harbour Tutoring Club"
    Then I should see "You are not authorized to perform this action."
