Feature: Authentication
  As a volunteer
  I want to log in
  So that I can manage my shifts

  Scenario: Logging in with valid credentials
    Given a user "vera@example.com" with password "password123"
    When I log in as "vera@example.com" with password "password123"
    Then I should see "Signed in successfully."

  Scenario: Logging in with a wrong password
    Given a user "vera@example.com" with password "password123"
    When I log in as "vera@example.com" with password "wrong-password"
    Then I should see "Invalid email or password."

  Scenario: Visitors must log in to see organizations
    When I go to the organizations page
    Then I should see "You need to sign in or sign up before continuing."
