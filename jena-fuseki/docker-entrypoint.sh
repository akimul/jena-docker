#!/bin/bash
#   Licensed to the Apache Software Foundation (ASF) under one or more
#   contributor license agreements.  See the NOTICE file distributed with
#   this work for additional information regarding copyright ownership.
#   The ASF licenses this file to You under the Apache License, Version 2.0
#   (the "License"); you may not use this file except in compliance with
#   the License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

set -e

if [ ! -f "$FUSEKI_BASE/shiro.ini" ] ; then
  # First time
  echo "###################################"
  echo "Initializing Apache Jena Fuseki"
  echo ""
  cp "$FUSEKI_HOME/shiro.ini" "$FUSEKI_BASE/shiro.ini"
  if [ -z "$ADMIN_PASSWORD" ] ; then
    ADMIN_PASSWORD='admin'
    echo "Randomly generated admin password:"
    echo ""
    echo "admin=$ADMIN_PASSWORD"
  fi
  echo ""
  echo "###################################"
fi

echo "creating config dir"
mkdir -p "$FUSEKI_BASE/configuration"

if [ -d "$FUSEKI_BASE/configuration" ]; then
  echo "copying ntb config"
  cp "$FUSEKI_HOME/ntb.ttl" "$FUSEKI_BASE/configuration/ntb.ttl"
  echo "copy done"
fi


if [ -f "$FUSEKI_BASE/system/tdb.lock" ]; then
  echo "removing tdb lock"
  rm "$FUSEKI_BASE/system/tdb.lock"
  echo "removed"
fi

if [ -f "$FUSEKI_BASE/databases/ntb/tdb.lock" ]; then
  echo "removing tdb lock"
  rm "$FUSEKI_BASE/databases/ntb/tdb.lock"
  echo "removed"
fi


# $ADMIN_PASSWORD can always override
if [ -n "$ADMIN_PASSWORD" ] ; then
  sed -i "s/^admin=.*/admin=$ADMIN_PASSWORD/" "$FUSEKI_BASE/shiro.ini"
fi

exec "$@" &

# Wait until server is up
while [[ $(curl -I http://localhost:3030 2>/dev/null | head -n 1 | cut -d$' ' -f2) != '200' ]]; do
  sleep 1s
done

# Convert env to datasets
printenv | egrep "^FUSEKI_DATASET_" | while read env_var
do
    dataset=$(echo $env_var | egrep -o "=.*$" | sed 's/^=//g')
    curl -s 'http://localhost:3030/$/datasets'\
         -H "Authorization: Basic $(echo -n admin:${ADMIN_PASSWORD} | base64)" \
         -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8'\
         --data "dbName=${dataset}&dbType=tdb"
done

wait
