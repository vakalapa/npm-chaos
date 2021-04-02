#!/bin/bash

alias k=kubectl
namespaces=(web0 web01 web02 web03 web04 web05 web06 web07 web08 web09 web10)

for i in ${namespaces[@]}; do
    k create ns $i
    sed 's/test1replace/$i/g' podDeployments/nginx_deployment.yaml > podDeployments/deployment-$i.yml
done

# Apply all pod deployments
#k apply -f podDeployments/




#for i in ${namespaces[@]}; do
#    k delete ns $i
#done
