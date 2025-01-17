#!/bin/bash
# Downloads a tarball artifact from AWS S3 and extracts it to the specified location.
#
# Usage: main.sh
#
# The following environment variables must be defined:
#   - INPUT_NAME - The name of the artifact
#   - INPUT_PATH - The path to be retrieved
#   - INPUT_PATTERN - not implemented yet
#   - INPUT_MERGE_MULTIPLE - not implemented yet
#   - INPUT_REPOSITORY - the repository the artifact is associated with
#   - INPUT_RUN_ID - the run ID the artifact is associated with
#   - RUNNER_OS - the OS of the runner
#   - S3_ARTIFACTS_BUCKET - the name of the AWS S3 bucket to use
#   - AWS_ACCESS_KEY_ID - the AWS access key ID (optional if uploading to a public S3 bucket)
#   - AWS_SECRET_ACCESS_KEY - the AWS secret access key (optional if uploading to a public S3 bucket)
#   - DRY_RUN - whether to run without uploading to AWS (optional, set to true to enable dry run)
#
# based on open-turo/actions-s3-artifact
# see: https://github.com/open-turo/actions-s3-artifact/blob/main/download/action.yaml

# exit immediately if an error occurs
set -e

#region import scripts
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/encoding.sh"
#endregion

#region read input arguments
echo "::debug::Inputs:"
echo "::debug::    INPUT_NAME:                  $INPUT_NAME"
echo "::debug::    INPUT_PATH:                  $INPUT_PATH"
echo "::debug::    INPUT_PATTERN:               $INPUT_PATTERN"
echo "::debug::    INPUT_MERGE_MULTIPLE:        $INPUT_MERGE_MULTIPLE"
echo "::debug::    INPUT_REPOSITORY:            $INPUT_REPOSITORY"
echo "::debug::    INPUT_RUN_ID:                $INPUT_RUN_ID"
echo "::debug::    RUNNER_OS:                   $RUNNER_OS"
echo "::debug::    S3_ARTIFACTS_BUCKET:         $S3_ARTIFACTS_BUCKET"
echo "::debug::    AWS_ACCESS_KEY_ID:           $AWS_ACCESS_KEY_ID"
echo "::debug::    AWS_SECRET_ACCESS_KEY:       $AWS_SECRET_ACCESS_KEY"
#endregion

#region validate input variables
# validate script input variables
if [[ "$INPUT_NAME" == "" ]]; then
    echo "::error::The values of 'NAME' input is not specified"
    ERROR=true
fi

if [[ "$INPUT_PATH" == "" ]]; then
    echo "::error::The values of 'PATH' input is not specified"
    ERROR=true
fi

if [[ "$INPUT_MERGE_MULTIPLE" == "" ]]; then
    echo "::error::The values of 'INPUT_MERGE_MULTIPLE' input is not specified"
    ERROR=true
fi

if [[ "$INPUT_REPOSITORY" == "" ]]; then
    echo "::error::The values of 'INPUT_REPOSITORY' input is not specified"
    ERROR=true
fi

if [[ "$INPUT_RUN_ID" == "" ]]; then
    echo "::error::The values of 'INPUT_RUN_ID' input is not specified"
    ERROR=true
fi

# validate github actions variables
if [[ "$RUNNER_OS" == "" ]]; then
    echo "::error::The values of 'RUNNER_OS' GitHub variable is not specified"
    ERROR=true
fi

if [[ "$DRY_RUN" != "true" ]]; then
    # check whether AWS credentials are specified and warn if they aren't
    if [[ "$AWS_ACCESS_KEY_ID" == "" || "$AWS_SECRET_ACCESS_KEY" == "" ]]; then
        echo "::warn::AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY is missing from environment variables."
        ERROR=true
    fi

    # check whether S3_ARTIFACTS_BUCKET is defined
    if [[ "$S3_ARTIFACTS_BUCKET" == "" ]]; then
        echo "::error::S3_ARTIFACTS_BUCKET is missing from environment variables."
        ERROR=true
    fi
fi

if [[ "$ERROR" == "true" ]]; then
    echo "::error::Input error(s) - exiting"
    exit 1
else
    echo "::debug::Validation complete"
fi
#endregion

#region create temp directories
# make sure that the path directory exists
mkdir -p "$INPUT_PATH"

# ensure we have a unique temporary directory to download to
TMP_ARTIFACT="$RUNNER_TEMP/download-s3-artifact"
if [[ "$RUNNER_OS" == "Windows" ]]; then
    # On some windows runners, the path for TMP_ARTIFACT is a mix of windows and unix path (both / and \), which
    # caused errors when un-taring. Converting to unix path resolves this.
    TMP_ARTIFACT=$(cygpath -u "$TMP_ARTIFACT")
fi
mkdir -p "$TMP_ARTIFACT"
echo "::debug::The artifact directory is $TMP_ARTIFACT"

# Create a unique directory for this particular action run
TMP_DIRECTORY="$(mktemp -d -p "$TMP_ARTIFACT" "download.XXXXXXXX")"
mkdir -p "$TMP_DIRECTORY"
echo "::debug::Created temporary directory $TMP_DIRECTORY"
#endregion

#region download artifact from AWS s3
# Target for download, this can be a single file or a tarball
TMP_FILE="$TMP_DIRECTORY/artifacts.tgz"

# Get AWS S3 bucket URI and ensure it starts with "s3://"
S3URI="$S3_ARTIFACTS_BUCKET"
if [[ "$S3URI" != s3://* ]]; then
    echo "::debug::Adding s3:// to bucket URI"
    S3URI="s3://$S3URI"
fi

# S3 URI to download
# Build key to object in S3 bucket
KEY="$INPUT_REPOSITORY/$INPUT_RUN_ID/$(urlencode $INPUT_NAME).tgz"
S3URI="${S3URI%/}/$KEY"

# Try to download
echo "::debug::aws s3 cp '$S3URI' '$TMP_FILE'"
if [[ "$DRY_RUN" == "true" ]]; then
    # copy test file for testing
    cp "./artifacts.tgz" "$TMP_FILE"
else
    aws s3 cp "$S3URI" "$TMP_FILE"
fi
echo "::debug::File downloaded successfully to $TMP_FILE"
#endregion

# Downloaded a tarball, extract it
# TODO: Should we check the path input to make sure it exists?
echo "::debug::tar -xzvf '$TMP_FILE' -C '$INPUT_PATH' $TAR_CLI_ARGS"
tar -xzvf "$TMP_FILE" -C "$INPUT_PATH" $TAR_CLI_ARGS

# list out everything in the extracted location
echo "::debug::Contents of our temporary directory"
if [[ "$RUNNER_OS" = "Windows" ]]; then
    echo "::debug::$(cmd //c tree //f "$INPUT_PATH")"
else
    echo "::debug::$(tree -a "$INPUT_PATH" 2>&1)"
fi
#endregion

#region generate outputs
# set output
# TODO: I don't think this output is correct. Need to investigate.
echo "download-path='$INPUT_PATH'" >> $GITHUB_OUTPUT
#endregion

#region clean up temp dir
# TODO: move to clean up step?
if [[ "$DRY_RUN" != "true" ]]; then
    rm -rf $TMP_ARTIFACT
fi
#endregion
