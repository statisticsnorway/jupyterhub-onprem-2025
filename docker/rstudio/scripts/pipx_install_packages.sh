#!/bin/bash

requirements_file="/tmp/requirements.txt"

# Read each line from the requirements file and install packages
# This allows snyk to scan for vulnerabilities
# And dependabot can be used to keep packages up to date
while IFS= read -r package || [ -n "$package" ]; do
    python -m pipx install "$package"
done < "$requirements_file"