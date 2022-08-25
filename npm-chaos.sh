#!/bin/bash
########################################################################
# USAGE:
# 1st arg is deletens, then will delete all generated NS
#
#
#
#
#
#
#######################################################################



#alias k=kubectl
namespaces=(web0)
labelsArray=(chaos=true)

#Global Limits
start=1
numOfNs=50
numofLabels=200
numofLoopForLabels=2
podFileName=pods_in_ns.txt
policyFileName=netpols_in_ns.txt

generateNs () {
    for (( i=$start; i<=$numOfNs; i++ ))
    do
        #sufix=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        sufix=test
        namespaces=("${namespaces[@]}" "web-$sufix-$i")
    done
}

generateLabels () {
    labelsArray=(chaos=true)
    for (( i=$start; i<=$numofLabels; i++ ))
    do
        labelKey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        labelVal=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
        labelsArray=("${labelsArray[@]}" "chaos-$labelKey=$labelVal")
    done
}

overwriteAllLabelsInNamespace () {
    overwrittenLabels=""
    for (( j=0; j<${#labelsArray[@]}; j++ ))
    do
        overwrittenLabels="$overwrittenLabels ${labelsArray[$j]}-extra"
    done
     kubectl label pods -n $1 --overwrite --all ${labelsArray[@]} $overwrittenLabels
}

labelAllPodsInNs () {    
    generateLabels
    kubectl label pods -n $1 --overwrite --all ${labelsArray[@]}
}

deleteRandomPodsNs () {
    echo "Deleting random pods in namespace $1"
    #list all pods in the namespace into a file
    kubectl get pods -n $1 | grep -v "NAME" | awk '{print $1}' > pods_in_ns.txt

    #get 10 random pods and delete them
    podname=$(shuf -n 10 pods_in_ns.txt | xargs)
    kubectl delete pod -n $1 $podname
}

deleteRandomPoliciesNs () {    
    echo "Deleting random Network Policies in namespace $1"
    #list all pods in the namespace into a file
    kubectl get netpol -n $1 | grep -v "NAME" | awk '{print $1}' > netpols_in_ns.txt

    #get 10 random netpols and delete them
    polname=$(shuf -n 10 netpols_in_ns.txt | xargs)
    kubectl delete netpol -n $1 $polname
}

deleteAllNetpols () {
    for ns in ${namespaces[@]}; do
        kubectl get netpol -n $ns | grep -v "NAME" | awk '{print $1}' > netpols_in_ns.txt

        #get 10 random netpols and delete them
        polname=$(cat netpols_in_ns.txt | xargs)
        kubectl delete netpol -n $ns $polname
    done
}

cleanUpAllResources () {    
    #delete old pod deployments
    rm podDeployments/deployment*.yml
    rm $podFileName
    rm $policyFileName
    echo "Deleting all created namespaces"
    kubectl delete ns ${namespaces[@]}
    exit 0
}

echo "Generating $numOfNs namespaces"
generateNs
echo "Done Generating NS"

echo ${namespaces[@]}


if [ "$1" = "deleteallpolicies" ]; then
    deleteAllNetpols
    exit 0
fi

if [ "$1" = "deletens" ]; then
    cleanUpAllResources
fi


kubectl create ns test1replace
#delete old pod deployments
rm podDeployments/deployment*.yml
for i in ${namespaces[@]}; do
    kubectl create ns $i
    sed "s/test1replace/$i/g" podDeployments/nginx_deployment.yaml > podDeployments/deployment-$i.yml
done

# Apply all pod deployments
kubectl apply -f podDeployments/

#Now apply labels to the deployment
for ns in ${namespaces[@]}; do
    echo "Applying Labels to $ns"
    for (( i=$start; i<=$numofLoopForLabels; i++ ))
    do               
        labelAllPodsInNs $ns
    done
done

#######################
if [ "$1" = "exitbeforenetpol" ]; then
    exit 0
fi
#######################

for ns in ${namespaces[@]}; do
    kubectl apply -n $ns -f networkPolicies/ 
done

if [ "$1" = "exitbeforenetpol" ]; then
    exit 0
fi

echo "#####################Deleting random pods and policies#############################"
for i in $(seq 1 50);do
    echo "/////////////////Welcome $i times/////////////////"

    for ns in ${namespaces[@]}; do
        echo "Deleting random pods in namespace $ns"
        #list and delete random pods in the namespace
        deleteRandomPodsNs $ns
        sleep 3
        #Re-add labels to new pods
        # labelAllPodsInNs $ns
        overwriteAllLabelsInNamespace $ns
        sleep 2        
        #list and delete random netpols in the namespace
        deleteRandomPoliciesNs $ns
        sleep 2
    done
    
    sleep 5
done

echo "exiting before cleanup"
exit 0

# Cleaning up all resources
cleanUpAllResources
