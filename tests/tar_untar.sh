#!/bin/bash
#
# Sets up environment variables and does a dry run execution of main.sh to test untaring the file. Creates file to be 
# untarred for testing.
#
# Usage: tar_untar.sh

#region set up environment variables
echo "Initializing variables"
export INPUT_NAME="tempArchiveName"
export INPUT_PATH="./tmp"
export INPUT_PATTERN=""
export INPUT_MERGE_MULTIPLE="false"
export INPUT_REPOSITORY="foo/bar"
export INPUT_RUN_ID="1"
export INPUT_INCLUDE_HIDDEN_FILES="false"
export RUNNER_OS="Windows"
export ENV_S3_ARTIFACTS_BUCKET="this-is-an-s3-bucket-name"
export ENV_AWS_ACCESS_KEY_ID=""
export ENV_AWS_SECRET_ACCESS_KEY=""
export DRY_RUN=true

# variables needed, but are usually defined by the GitHub runner
export RUNNER_TEMP="$TEMP"
export RUNNER_DEBUG=true
export GITHUB_OUTPUT=/dev/null
#endregion

#region generate test file
echo "Generating test files"
mkdir -p "origTmp"
mkdir -p "origTmp/folder1"
mkdir -p "origTmp/folder2"

touch "origTmp/file1.txt"
touch "origTmp/folder1/file2.txt"
touch "origTmp/folder2/file3.txt"

GZIP=-6 tar -zcvf "./artifacts.tgz" -C "origTmp" .
#endregion

#region run main script
echo "Running main.sh"
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/../scripts/main.sh"
#endregion

#region verify that the untar happened correctly
echo "Comparing folders"
diff -r "$INPUT_PATH/origTmp" "origTmp"
#endregion