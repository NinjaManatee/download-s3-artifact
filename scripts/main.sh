#!/bin/bash
# Downloads a tarball artifact from AWS S3 and extracts it to the specified location.
#
# based on open-turo/actions-s3-artifact
# see: https://github.com/open-turo/actions-s3-artifact/blob/main/download/action.yaml

#region import scripts
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/encoding.sh"
#endregion

#region read input arguments
INPUT_NAME="$1"
INPUT_PATH="$2"
INPUT_MERGE_MULTIPLE="$3"
INPUT_REPOSITORY="$4"
INPUT_RUN_ID="$5"
RUNNER_OS="$6"
ENV_S3_ARTIFACTS_BUCKET="$7"
ENV_AWS_ACCESS_KEY_ID="$8"
ENV_AWS_SECRET_ACCESS_KEY="$9"
INPUT_PATTERN="$10"
#endregion

#region validate input variables
# validate script input variables
if [[ "$INPUT_NAME" == "" ]]; then
    echo "::error::The values of 'NAME' input is not specified"
fi

if [[ "$INPUT_PATH" == "" ]]; then
    echo "::error::The values of 'PATH' input is not specified"
fi

if [[ "$INPUT_PATTERN" == "" ]]; then
    echo "::error::The values of 'INPUT_PATTERN' input is not specified"
fi

if [[ "$INPUT_MERGE_MULTIPLE" == "" ]]; then
    echo "::error::The values of 'INPUT_MERGE_MULTIPLE' input is not specified"
fi

if [[ "$INPUT_REPOSITORY" == "" ]]; then
    echo "::error::The values of 'INPUT_REPOSITORY' input is not specified"
fi

if [[ "$INPUT_RUN_ID" == "" ]]; then
    echo "::error::The values of 'INPUT_RUN_ID' input is not specified"
fi

# validate github actions variables
if [[ "$RUNNER_OS" == "" ]]; then
    echo "::error::The values of 'RUNNER_OS' GitHub variable is not specified"
fi

# check whether AWS credentials are specified and warn if they aren't
if [[ "$ENV_AWS_ACCESS_KEY_ID" == "" || "$ENV_AWS_SECRET_ACCESS_KEY" == "" ]]; then
    echo "::warn::AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY is missing from environment variables."
fi

# check whether S3_ARTIFACTS_BUCKET is defined
if [[ "$ENV_S3_ARTIFACTS_BUCKET" == "" ]]; then
    echo "::error::S3_ARTIFACTS_BUCKET is missing from environment variables."
    exit 1
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

# Create a unique directory for this particular action run
TMPDIR="$(mktemp -d -p "$TMP_ARTIFACT" "download.XXXXXXXX")"
echo "::debug::Created temporary directory $TMPDIR"
#endregion

#region download artifact from AWS s3
# Target for download, this can be a single file or a tarball
TMPFILE="$TMPDIR/download-s3-artifact/artifact.tgz"

# Get AWS S3 bucket URI and ensure it starts with "s3://"
S3URI="$ENV_S3_ARTIFACTS_BUCKET"
if [[ "$S3URI" != s3://* ]]; then
    echo "::debug::Adding s3:// to bucket URI"
    S3URI="s3://$S3URI"
fi

# S3 URI to download
# Build key to object in S3 bucket
KEY="$INPUT_REPOSITORY/$INPUT_RUN_ID/$(urlencode $INPUT_NAME).tgz"
S3URI="${S3URI%/}/$KEY"

# Try to download
echo "::debug::aws s3 cp '$S3URI' '$TMPFILE'"
aws s3 cp "$S3URI" "$TMPFILE"
echo "::debug::File downloaded successfully to $TMPFILE"
#endregion

#region untar downloaded artifact
# TODO: What does this do and do we need it?
# if [[ -n "${{ inputs.strip }}" ]]; then
#   TAR_CLI_ARGS="--strip-components=${{ inputs.strip }}"
# fi

# Downloaded a tarball, extract it
# TODO: Should we check the path input to make sure it is in the project?
echo "::debug::tar -xzvf '$TMPFILE' -C '$INPUT_PATH' $TAR_CLI_ARGS"
tar -xzvf "$TMPFILE" -C "$INPUT_PATH" $TAR_CLI_ARGS

if [[ -n "$RUNNER_DEBUG" ]]; then
    echo "::debug::Contents of artifact path"
    echo "$(tree -a '$INPUT_PATH' 2>&1)"
fi
#endregion

#region generate outputs
# set output
# TODO: I don't think this output is correct. Need to investigate.
echo "download-path='$INPUT_PATH'" >>$GITHUB_OUTPUT
#endregion

#region clean up temp dir
# clean up temp files
rm -rf $TMP_ARTIFACT
#endregion
