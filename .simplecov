# Shared configuration for RSpec and Cucumber. Coverage is started in
# spec/rails_helper.rb and features/support/env.rb, and the results of both
# suites are merged into coverage/index.html.
SimpleCov.profiles.define "shiftup" do
  load_profile "rails"
  enable_coverage :branch
  skip "/app/channels/"
  skip "/app/jobs/application_job.rb"
  skip "/app/mailers/application_mailer.rb"
  minimum_coverage ENV.fetch("COVERAGE_MINIMUM", 80).to_i if ENV["COVERAGE_CHECK"]
end
