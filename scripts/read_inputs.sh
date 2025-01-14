#!/bin/bash
# Reads inputs for GitHub action into variables used by main.sh

# read inputs into variables
INPUT_NAME="${{ inputs.name }}"
INPUT_PATH="${{ inputs.path }}"
if [[ "$INPUT_PATH" == "" ]]; then
    INPUT_PATH="${{ github.workspace }}"
fi
INPUT_PATTERN="${{ inputs.pattern }}"
INPUT_MERGE_MULTIPLE="${{ inputs.merge_multiple }}"
INPUT_REPOSITORY="${{ inputs.repository }}"
if [[ "$INPUT_REPOSITORY" == "" ]]; then
    INPUT_REPOSITORY="${{ github.repository }}"
fi
INPUT_RUN_ID="${{ inputs.run-id }}"
if [[ "$INPUT_RUN_ID" == "" ]]; then
    INPUT_RUN_ID="${{ github.run-id }}"
fi

# read github actions variables
RUNNER_OS="${{ runner.os }}"

# read environment variables
# TODO: Are these necessary since they are already environment variables?
ENV_S3_ARTIFACTS_BUCKET="${{ env.S3_ARTIFACTS_BUCKET }}"
ENV_AWS_ACCESS_KEY_ID="${{ env.AWS_ACCESS_KEY_ID }}"
ENV_AWS_SECRET_ACCESS_KEY="${{ env.AWS_SECRET_ACCESS_KEY }}"

# print inputs for debugging
echo "::debug::Inputs:"
echo "::debug::\tname: $INPUT_NAME"
echo "::debug::\tpath: $INPUT_PATH"
echo "::debug::\tpattern: $INPUT_PATTERN"
echo "::debug::\tmerge-multiple: $INPUT_MERGE_MULTIPLE"
echo "::debug::\trepository: $INPUT_REPOSITORY"
echo "::debug::\run-id: $INPUT_RUN_ID"