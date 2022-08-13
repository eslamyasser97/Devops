#!/bin/bash
function secret_file() {
    echo "enter your db username you want"
    read name
    echo "enter your db password you want"
    read passwd

    name_encrypt=$(echo "$name" | base64)
    passw_encrypt=$(echo "$passwd" | base64)
    echo "name is $name_encrypt"

    mkdir db-config 
    echo -n "apiVersion: v1
kind: Secret
metadata:
    name: mongodb-secret
type: Opaque
data:
    mongo-root-username: $name_encrypt      
    mongo-root-password: $passw_encrypt  
" > db-config/mongo-secret.yaml
    echo "secret file is created"
}


function replicas() {
  while true
    do
    echo "enter your replicas (it must be integer value)"
    read replicas
    re='^[0-9]+$'
    if ! [[ $replicas =~ $re ]] && [[ $replicas -lt 0 || $replicas -eq 0 ]] ; then
        echo "error: Not a number" 
    else 
        echo " replicas = $replicas"
        return $replicas ; exit     
 fi
 done     
}

function mongo_configmap() {
echo "apiVersion: v1
kind: ConfigMap
metadata:
  name: mongodb-configmap
data:
  database_url: mongodb-service

" > db-config/mongo-configmap.yaml
    echo "mongo-configmap file is created"
}
function mongo() {
    echo "
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  labels:
    app: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom: 
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-password

" > db-config/mongodb.yaml
echo "mongo file is created" ;

}

function replicas() {
  while true
    do
    echo "enter your replicas (it must be integer value)"
    read replicas
    re='^[0-9]+$'
    if ! [[ $replicas =~ $re ]] && [[ $replicas -lt 0 || $replicas -eq 0 ]] ; then
        echo "error: Not a number" 
    else 
        echo " replicas = $replicas"
        return $replicas   
 fi
 done     
}

function mongo_express(){
    echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-express
  labels:
    app: mongo-express
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-express
  template:
    metadata:
      labels:
        app: mongo-express
    spec:
      containers:
      - name: mongo-express
        image: mongo-express
        ports:
        - containerPort: 8081
        env:
        - name: ME_CONFIG_MONGODB_ADMINUSERNAME
          valueFrom:
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-username
        - name: ME_CONFIG_MONGODB_ADMINPASSWORD
          valueFrom: 
            secretKeyRef:
              name: mongodb-secret
              key: mongo-root-password
        - name: ME_CONFIG_MONGODB_SERVER
          valueFrom: 
            configMapKeyRef:
              name: mongodb-configmap
              key: database_url
" > db-config/mongo-express.yaml
    echo "mongo-express file is created"
}
function mongo_service() {
    echo "apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  selector:
    app: mongodb 
  ports:
    - protocol: TCP
      port: 27017 
      targetPort: 27017 

---
apiVersion: v1
kind: Service
metadata:
  name: mongo-express-service
spec:
  selector:
    app: mongo-express
  type: LoadBalancer  
  ports:
    - protocol: TCP
      port: 8081
      targetPort: 8081
      nodePort: 30000
" > db-config/mongo-service.yaml
    echo "mongo-service file is created"
}
function build() {
    kubectl apply -f db-config/mongo-secret.yaml
    kubectl apply -f db-config/mongodb.yaml
    kubectl apply -f db-config/mongo-configmap.yaml 
    kubectl apply -f db-config/mongo-express.yaml
    kubectl apply -f db-config/mongo-service.yaml
    echo "great" ; sleep 10
    minikube service mongo-express-service
}
secret_file
mongo_configmap
replicas= echo " $? "  
echo $replicas
mongo $replicas
mongo_express
mongo_service
build
