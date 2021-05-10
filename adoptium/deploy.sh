#!/usr/bin/env bash 

jsonnet -e '(import "agent.jsonnet").newDeployment("adoptium", "codesigning-agent")' | jq '.kube.resources[]' | kubectl apply -f -