#!/usr/bin/env bash

# !$1 is expected to be provided, this is the URL for the endpoint for nodejs to talk to
# !$2 is whether or not to reuse connections and should be one of true/false
# !Can specify $3 as the tag
# !Default tag is a prebuilt version hosted on public docker hub (https://hub.docker.com/repository/docker/champgoblem/gvisor-nodejs-test)

tag="${3:-"champgoblem/gvisor-nodejs-test:latest"}"

if [ "$1" == "" ]; then
  echo "No remote URL provided"
  exit 1
fi

if [ "$2" == "false" ]; then
  name="nodejs-test-no-reuse"
  echo "Deploying k6 test with NO connection reuse"
elif [ "$2" == "true" ]; then
  name="nodejs-test-connection-reuse"
  echo "Deploying k6 test with connection reuse"
else
  echo '$2 should be one of [true, false]'
  echo "true -> reuse connections"
  echo "false -> dont reuse"
  exit 1
fi

echo "Using tag $tag"

# Deploy the pod that starts the test with the nodejs test
# A variety of ENVs can be configured
# SLEEP -> Wait between each group running
# GROUP_SIZE -> The number of calls made per group
# MAX_GROUPS -> The number of groups to run
# ASYNC_GATE -> Whether or not to wait for all calls in a group to resolve
# KEEPALIVE -> Set to reuse connections or not
# URL -> The endpoint for k6 to talk to
kubectl apply -f - << EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $name
spec:
  activeDeadlineSeconds: 36000
  backoffLimit: 0
  completions: 1
  parallelism: 1
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
    spec:
      containers:
      - name: nodejs
        image: $tag
        imagePullPolicy: Always
        env:
        - name: KEEPALIVE
          value: "$2"
        - name: URL
          value: $1
        - name: MAX_GROUPS
          value: "1000"
      runtimeClassName: gvisor
      restartPolicy: Never
EOF