#!/bin/bash

source "$HOME/.rvm/scripts/rvm"

ROOT_DIR="$( dirname "$0" )/.."
cd "$ROOT_DIR"

bundle exec ruby ./bin/fetch_repositories.rb
