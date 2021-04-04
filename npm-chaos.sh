#!/bin/bash

#alias k=kubectl
namespaces=(web0 web01 web02 web03 web04 web05 web06 web07 web08 web09 web10)
labelsArray=(chaos=true)

generateNs () {
    for i in {1..100}
    do
        #sufix=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        sufix=test
        namespaces=("${namespaces[@]}" "web-$sufix-$i")
    done
}

generateLabels () {
    labelsArray=(chaos=true)
    for i in {1..100}
    do
        labelKey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        labelVal=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        labelsArray=("${labelsArray[@]}" "chaos-$labelKey=$labelVal")
    done
}

echo "Generating $numOfNs namespaces"
generateNs
echo "Done Generating NS"

echo ${namespaces[@]}

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
        generateLabels
        kubectl label pods -n $ns --all ${labelsArray[@]}
    done
done

for ns in ${namespaces[@]}; do
    kubectl apply -n $ns -f networkPolicies/ 
done


echo "#####################Deleting random pods#############################"
for i in $(seq 1 50);do
    echo "/////////////////Welcome $i times/////////////////"

    for ns in ${namespaces[@]}; do
        echo "Deleting random pods in namespace $ns"
        #list all pods in the namespace into a file
        kubectl get pods -n $ns | awk '{print $1}' > pods_in_ns.txt

        #get 10 random pods and delete them
        podname=$(shuf -n 10 testkgp | xargs)
        kubectl delete pod -n $ns $podname
        sleep 3

        generateLabels
        kubectl label pods -n $ns --all ${labelsArray[@]}

    done
    
    sleep 5
done

#k delete ns ${namespaces[@]}
