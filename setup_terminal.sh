#!/bin/bash

# Create Directories
mkdir ~/dev
mkdir ~/web
mkdir ~/training

# Setup Git
git config --global init.defaultBranch prod
git config --global user.name "Amy Kapernick"
git config --global user.email "amy@kapers.dev"

# Setup Node Init
npm set init.author.name "Amy Kapernick"
npm set init.author.email "amy@kapers.dev"
npm set init.author.url "https://amyskapers.dev"
npm set init.license "MIT"
npm set init.version "1.0.0"
