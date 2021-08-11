#!/usr/bin/env bash

# !Requires istioctl installed
# !Issues seen on istio versions 1.9.5/1.9.6/1.9.7/1.10.3 (and potentially more)

# Generate and install the manifest given by profile.yaml
istioctl manifest install -y -f ./profile.yaml
