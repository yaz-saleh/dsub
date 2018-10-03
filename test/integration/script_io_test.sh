#!/bin/bash

# Copyright 2016 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# script_io_tests.sh
#
# Basic pipeline script, which exercises file localization/de-localiation,
# or exercises GCS bucket mounting if --mount is used.
# Note: The behavior of this script is coupled to the implementation of output
#       checks defined in io_setup.sh and io_tasks_setup.sh.
#       Changes here could break these tests.
#
# The script must be run with either:
#   INPUT_PATH: file or directory where files have been localized,
#       such as "/mnt/data/input/gs/bucket/path/"
#       or "/mnt/data/input/gs/bucket/path/file.bam"
#
#   OR
#
#   GENOMICS_PUBLIC_BUCKET: A directory mounted to a GCS bucket,
#       such as "/mnt/data/bucket"
#
#   AND
#
#   OUTPUT_PATH: path where files will be de-localized from,
#       such as "/mnt/data/output/gs/bucket/path/*"
#       or "/mnt/data/output/gs/bucket/path/file.md5"
#

set -o errexit
set -o nounset

echo "GENOMICS_PUBLIC_BUCKET = ${GENOMICS_PUBLIC_BUCKET:-}"
echo "POPULATION_FILE_PATH = ${POPULATION_FILE_PATH:-}"
echo "OUTPUT_POPULATION_FILE = ${OUTPUT_POPULATION_FILE}"

echo "INPUT_PATH = ${INPUT_PATH:-}"
echo "OUTPUT_PATH = ${OUTPUT_PATH}"

if [[ -n "${GENOMICS_PUBLIC_BUCKET:-}" ]]; then
  if [[ -n "${INPUT_PATH:-}" ]]; then
    echo "Invalid test: GENOMICS_PUBLIC_BUCKET and INPUT_PATH should not both be set"
    exit 1
  fi
  if [[ -n "${POPULATION_FILE_PATH:-}" ]]; then
    echo "Invalid test: GENOMICS_PUBLIC_BUCKET and POPULATION_FILE_PATH should not both be set"
    exit 1
  fi
  # Set the INPUT PATH based on the bucket
  # GENOMICS_PUBLIC_DATA is the path representing the bucket root.
  # Get the rest of the path from env vars.
  INPUT_PATH="${GENOMICS_PUBLIC_BUCKET}/${INPUT_BAM}"
  POPULATION_FILE_PATH="${GENOMICS_PUBLIC_BUCKET}/${POPULATION_FILE}"
fi

if [[ -d "${INPUT_PATH}" ]]; then
  readonly INPUT_DIR="${INPUT_PATH}"
else
  readonly INPUT_DIR="$(dirname "${INPUT_PATH}")"
fi

readonly OUTPUT_DIR="$(dirname "${OUTPUT_PATH}")"

echo "INPUT_DIR = ${INPUT_DIR}"
echo "OUTPUT_DIR = ${OUTPUT_DIR}"

cd "${INPUT_DIR}"

readonly INPUT_FILE_LIST="$(ls "${INPUT_PATH}")"

for INPUT_FILE in "${INPUT_FILE_LIST[@]}"; do
  FILE_NAME="$(basename "${INPUT_FILE}")"

  md5sum "${INPUT_FILE}" | awk '{ print $1 }' > "${OUTPUT_DIR}/${FILE_NAME}.md5"
done

# Write the md5 for the population file to a task-specific output location
md5sum "${POPULATION_FILE_PATH}" | awk '{ print $1 }' \
  > "$(dirname "${OUTPUT_POPULATION_FILE}")/${TASK_ID}.md5"
