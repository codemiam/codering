#!/bin/sh

docker build --no-cache -t codering/test-php-simple .
docker tag codering/test-php-simple:latest $(minikube ip):5000/codering-test-php-simple:latest
docker push $(minikube ip):5000/codering-test-php-simple
nuctl deploy test-php-simple --run-image codering-test-php-simple:latest --runtime shell --handler "proxy-function.sh" --namespace nuclio --registry $(minikube ip):5000 --run-registry localhost:5000

# Then test with:
# nuctl invoke test-php-simple