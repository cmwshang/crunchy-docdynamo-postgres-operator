#!/bin/bash

# Copyright 2017 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

NAME="$1"
OPERATION="$2"

if [[ "$#" -le 1 ]]; then
  echo "Usage:"
  echo "   $0 <name> <operation>"
  echo "   - name: all | commands | configuration"
  echo "   - operation: create | delete"
  exit
fi

function create {
  local cname="$1"

  # Define page title
  export TITLE=`echo "${cname}"`

  # Convert documentation using asciidoctor
  python /crunchy-docdynamo-postgres-operator/asciidoc/asciidoc.py -v -b docdynamo -o /crunchy-docdynamo-postgres-operator/doc/xml/$cname.xml /postgres-operator/docs/$cname.asciidoc
}


if [[ ${NAME?} == "all" ]]; then
  docs="commands configuration"
else
  docs="${NAME}"
fi

for doc in $docs; do
  case $OPERATION in
    create)
      create "$doc"
      ;;
  esac
done
