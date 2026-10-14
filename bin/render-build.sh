#!/usr/bin/env bash
# Build script for Render (see render.yaml). Exits on the first error.
set -o errexit

bundle install
bin/rails assets:precompile
bin/rails assets:clean

# Render's free tier has no pre-deploy step, so migrations run during the build.
bin/rails db:migrate
# Seeds are idempotent: they create the demo organizations and accounts only if missing.
bin/rails db:seed
