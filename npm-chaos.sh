#!/bin/bash

#alias k=kubectl
namespaces=(web0 web01 web02 web03 web04 web05 web06 web07 web08 web09 web10)

kubectl create ns test1replace
for i in ${namespaces[@]}; do
    kubectl create ns $i
    sed "s/test1replace/$i/g" podDeployments/nginx_deployment.yaml > podDeployments/deployment-$i.yml
done

# Apply all pod deployments
kubectl apply -f podDeployments/

#Now apply labels to the deployment
for ns in ${namespaces[@]}; do
    echo "Applying Labels to $ns"
    for i in {1..30}
    do               
        labelKey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        labelVal=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        kubectl label pods -n $ns --all chaos-$labelKey=$labelVal
    done
done

for ns in ${namespaces[@]}; do
    kubectl apply -n $ns -f networkPolicies/ 
done


#for i in ${namespaces[@]}; do
#    k delete ns $i
#done
