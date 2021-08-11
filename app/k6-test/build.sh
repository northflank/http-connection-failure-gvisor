#!/usr/bin/env bash

# !Expects $1 to be a tag for the image of the form <name>:<tag>

if [ "$1" == "" ]; then
  echo "No tag for building image"
  exit 1
fi

echo "Building"
docker build -t $1 .

echo "Pushing"
docker push $1

echo "Built and pushed image $1"