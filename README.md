# download-s3-artifact
GitHub Action that parallels NinjaManatee/download-s3-artifact but download from AWS S3 instead of GitHub

# `@NinjaManatee/download-s3-artifact`

Download [Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts) from your Workflow Runs. Internally powered by the [@actions/artifact](https://github.com/actions/toolkit/tree/main/packages/artifact) package.

See also [upload-s3-artifact](https://github.com/NBinjaManatee/upload-s3-artifact).

- [`download-s3-artifact`](#download-s3-artifact)
  - [Usage](#usage)
    - [Inputs](#inputs)
    - [Outputs](#outputs)
  - [Examples](#examples)
    - [Download Single Artifact](#download-single-artifact)
    <!-- TODO: These sections need to be implemented
    - [Download All Artifacts](#download-all-artifacts)
    - [Download multiple (filtered) Artifacts to the same directory](#download-multiple-filtered-artifacts-to-the-same-directory)
    - [Download Artifacts from other Workflow Runs or Repositories](#download-artifacts-from-other-workflow-runs-or-repositories)
    -->

## Usage

In general, the usage for `download-s3-artifact` is the same as with `actions/upload-artifact@v4`, except where it hasn't been implemented yet.

### Inputs

```yaml
- uses: NinjaManatee/download-s3-artifact@main
  with:
    # Name of the artifact to download.
    # If unspecified, all artifacts for the run are downloaded.
    # Optional.
    name:

    # Destination path. Supports basic tilde expansion.
    # Optional. Default is $GITHUB_WORKSPACE
    path:

    # A glob pattern to the artifacts that should be downloaded.
    # Ignored if name is specified.
    # Optional.
    pattern:

    # When multiple artifacts are matched, this changes the behavior of the destination directories.
    # If true, the downloaded artifacts will be in the same directory specified by path.
    # If false, the downloaded artifacts will be extracted into individual named directories within the specified path.
    # Optional. Default is 'false'
    merge-multiple:

    # The GitHub token used to authenticate with the GitHub API.
    # This is required when downloading artifacts from a different repository or from a different workflow run.
    # Optional. If unspecified, the action will download artifacts from the current repo and the current workflow run.
    github-token:

    # The repository owner and the repository name joined together by "/".
    # If github-token is specified, this is the repository that artifacts will be downloaded from.
    # Optional. Default is ${{ github.repository }}
    repository:

    # The id of the workflow run where the desired download artifact was uploaded from.
    # If github-token is specified, this is the run that artifacts will be downloaded from.
    # Optional. Default is ${{ github.run_id }}
    run-id:
```

### Outputs

| Name | Description | Example |
| - | - | - |
| `download-path` | Absolute path where the artifact(s) were downloaded | `/tmp/my/download/path` |

## Examples

### Download Single Artifact

Download to current working directory (`$GITHUB_WORKSPACE`):

```yaml
steps:
- uses: NinjaManatee/download-s3-artifact@main
  with:
    name: my-artifact
- name: Display structure of downloaded files
  run: ls -R
```

Download to a specific directory (also supports `~` expansion):

```yaml
steps:
- uses: NinjaManatee/download-s3-artifact@main
  with:
    name: my-artifact
    path: your/destination/dir
- name: Display structure of downloaded files
  run: ls -R your/destination/dir
```

<!-- TODO: I don't now whether this behavior works
### Download All Artifacts

If the `name` input parameter is not provided, all artifacts will be downloaded. To differentiate between downloaded artifacts, by default a directory denoted by the artifacts name will be created for each individual artifact. This behavior can be changed with the `merge-multiple` input parameter.

Example, if there are two artifacts `Artifact-A` and `Artifact-B`, and the directory is `etc/usr/artifacts/`, the directory structure will look like this:

```
etc/usr/artifacts/
    Artifact-A/
        ... contents of Artifact-A
    Artifact-B/
        ... contents of Artifact-B
```

Download all artifacts to the current working directory:

```yaml
steps:
- uses: NinjaManatee/download-s3-artifact@main
- name: Display structure of downloaded files
  run: ls -R
```

Download all artifacts to a specific directory:

```yaml
steps:
- uses: NinjaManatee/download-s3-artifact@main
  with:
    path: path/to/artifacts
- name: Display structure of downloaded files
  run: ls -R path/to/artifacts
```

To download them to the _same_ directory:

```yaml
steps:
- uses: NinjaManatee/download-s3-artifact@main
  with:
    path: path/to/artifacts
    merge-multiple: true
- name: Display structure of downloaded files
  run: ls -R path/to/artifacts
```

Which will result in:

```
path/to/artifacts/
    ... contents of Artifact-A
    ... contents of Artifact-B
```
-->

<!-- TODO: This hasn't been implemented yet
### Download multiple (filtered) Artifacts to the same directory

In multiple arch/os scenarios, you may have Artifacts built in different jobs. To download all Artifacts to the same directory (or matching a glob pattern), you can use the `pattern` and `merge-multiple` inputs.

```yaml
jobs:
  upload:
    strategy:
      matrix:
        runs-on: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.runs-on }}
    steps:
    - name: Create a File
      run: echo "hello from ${{ matrix.runs-on }}" > file-${{ matrix.runs-on }}.txt
    - name: Upload Artifact
      uses: actions/upload-artifact@main
      with:
        name: my-artifact-${{ matrix.runs-on }}
        path: file-${{ matrix.runs-on }}.txt
  download:
    needs: upload
    runs-on: ubuntu-latest
    steps:
    - name: Download All Artifacts
      uses: NinjaManatee/download-s3-artifact@main
      with:
        path: my-artifact
        pattern: my-artifact-*
        merge-multiple: true
    - run: ls -R my-artifact
```

This results in a directory like so:

```
my-artifact/
  file-macos-latest.txt
  file-ubuntu-latest.txt
  file-windows-latest.txt
```
-->

### Download Artifacts from other Workflow Runs or Repositories

It may be useful to download Artifacts from other workflow runs, or even other repositories:

```yaml
steps:
- uses: NinjaManatee/download-s3-artifact@main
  with:
    name: my-other-artifact
    repository: actions/toolkit
    run-id: 1234
```