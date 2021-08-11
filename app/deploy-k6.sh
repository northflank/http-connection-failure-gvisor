#!/usr/bin/env bash

# !$1 is expected to be provided, this is the URL for the endpoint for k6 to talk to
# !$2 is whether or not to reuse connections and should be one of true/false
# !Can specify $3 as the tag
# !Default tag is a prebuilt version hosted on public docker hub (https://hub.docker.com/repository/docker/champgoblem/gvisor-k6-test)

tag="${3:-"champgoblem/gvisor-k6-test:latest"}"

if [ "$1" == "" ]; then
  echo "No remote URL provided"
  exit 1
fi

if [ "$2" == "true" ]; then
  name="k6-test-connection-reuse"
  echo "Deploying k6 test with connection reuse"
elif [ "$2" == "false" ]; then
  name="k6-test-no-reuse"
  echo "Deploying k6 test with NO connection reuse"
else
  echo '$2 should be one of:'
  echo "true -> reuse connections"
  echo "false -> dont reuse connections"
  exit 1
fi

echo "Using tag $tag"

# Deploy the pod that starts the test with the k6 load testing tool
# A variety of ENVs can be configured
# VUS -> The number of user agents to use (defualt 5)
# DURATION -> The length of time to run the test for (default 10m)
# NO_CONNECTION_REUSE -> Set to false/true to reuse connections or not
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
      - name: k6
        image: $tag
        imagePullPolicy: Always
        env:
        - name: VUS
          value: "5"
        - name: DURATION
          value: 10m
        - name: REUSE_CONNECTION
          value: "$2"
        - name: URL
          value: $1
      runtimeClassName: gvisor
      restartPolicy: Never
EOF