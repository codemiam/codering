## 26 oct. 2018

Pas mal de galères pour installer Minikube en v0.30.0 (hangs), donc install d'une version plus ancienne :

``` sh
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.25.2/minikube-linux-amd64 && chmod +x minikube && sudo cp minikube /usr/local/bin/ && rm minikube
```

Démarrage du cluster comme requis sur https://nuclio.io/docs/latest/setup/minikube/getting-started-minikube/ :

``` sh
minikube start --vm-driver=virtualbox --extra-config=apiserver.Authorization.Mode=RBAC

There is a newer version of minikube available (v0.30.0).  Download it here:
https://github.com/kubernetes/minikube/releases/tag/v0.30.0

To disable this notification, run the following:
minikube config set WantUpdateNotification false
Starting local Kubernetes v1.9.4 cluster...
Starting VM...
Getting VM IP address...
Kubernetes version downgrade is not supported. Using version: v1.10.0
Moving files into cluster...
Downloading localkube binary
 173.54 MB / 173.54 MB [============================================] 100.00% 0s
 0 B / 65 B [----------------------------------------------------------]   0.00%
 65 B / 65 B [======================================================] 100.00% 0sSetting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.
```

Vérification avec `kubectl cluster-infos`, tout roule.

``` sh
Kubernetes master is running at https://192.168.99.100:8443

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Puis suite des instructions sur la page ci-dessus :

``` sh
kubectl apply -f https://raw.githubusercontent.com/nuclio/nuclio/master/hack/minikube/resources/kubedns-rbac.yaml

clusterrole.rbac.authorization.k8s.io/cluster-writer created
clusterrole.rbac.authorization.k8s.io/cluster-reader created
clusterrolebinding.rbac.authorization.k8s.io/cluster-write created
clusterrolebinding.rbac.authorization.k8s.io/cluster-read created
rolebinding.rbac.authorization.k8s.io/sd-build-write created
```

``` sh
minikube ssh -- docker run -d -p 5000:5000 registry:2

Unable to find image 'registry:2' locally
2: Pulling from library/registry
d6a5679aa3cf: Pull complete
ad0eac849f8f: Pull complete
2261ba058a15: Pull complete
f296fda86f10: Pull complete
bcd4a541795b: Pull complete
Digest: sha256:5a156ff125e5a12ac7fdec2b90b7e2ae5120fa249cf62248337b6d04abc574c8
Status: Downloaded newer image for registry:2
01908ddcc591e636394089ab35077bd0aa4b1195b303b20679a3cb446e2050d7
```

``` sh
kubectl create namespace nuclio
namespace/nuclio created
```

``` sh
kubectl apply -f https://raw.githubusercontent.com/nuclio/nuclio/master/hack/k8s/resources/nuclio-rbac.yaml

role.rbac.authorization.k8s.io/nuclio-function-deployer created
rolebinding.rbac.authorization.k8s.io/nuclio-function-deployer-rolebinding created
clusterrole.rbac.authorization.k8s.io/nuclio-functioncr-admin created
clusterrolebinding.rbac.authorization.k8s.io/nuclio-functioncr-admin-clusterrolebinding created
```

``` sh
kubectl apply -f https://raw.githubusercontent.com/nuclio/nuclio/master/hack/k8s/resources/nuclio.yaml

customresourcedefinition.apiextensions.k8s.io/functions.nuclio.io created
customresourcedefinition.apiextensions.k8s.io/projects.nuclio.io created
customresourcedefinition.apiextensions.k8s.io/functionevents.nuclio.io created
serviceaccount/nuclio created
deployment.apps/nuclio-controller created
deployment.apps/nuclio-dashboard created
service/nuclio-dashboard created
```

``` sh
kubectl get pods --namespace nuclio
NAME                                 READY   STATUS    RESTARTS   AGE
nuclio-controller-7496b67fc6-7vvq8   1/1     Running   0          1m
nuclio-dashboard-66dc8dcbb7-54jvf    1/1     Running   0          1m
```

``` sh
kubectl port-forward -n nuclio $(kubectl get pods -n nuclio -l nuclio.io/app=dashboard -o jsonpath='{.items[0].metadata.name}') 8070:8070

kubectl port-forward -n nuclio $(kubectl get pods -n nuclio -l nuclio.io/app=dashboard -o jsonpath='{.items[0].metadata.name}') 8070:8070

Forwarding from 127.0.0.1:8070 -> 8070
Forwarding from [::1]:8070 -> 8070
Handling connection for 8070
Handling connection for 8070
```

Cette dernière commande ne rend pas la main, le dashboard nuclio est accessible sur http://localhost:8070 comme prévu.

Déploiement d'une fonction built-in (Dates nodejs) sur le FaaS :

```
[00:10:36.643] (I) Deploying function
[00:10:36.666] (I) Building
[00:10:36.694] (I) Staging files and preparing base images
[00:10:36.695] (I) Building processor image
[00:10:36.695] (I) Pulling image [imageName: "nuclio/handler-builder-nodejs-onbuild:0.5.14-amd64"]
[00:11:17.101] (I) Pushing image [from: "nuclio/processor-test-nodejs:latest", to: "localhost:5000/nuclio/processor-test-nodejs:latest"]
[00:12:03.608] (I) Build complete [result: {"Image":"nuclio/processor-test-nodejs:latest","UpdatedFunctionConfig":{"metadata":{"labels":{"nuclio.io/project-name":"c725e62d-b084-4553-b16f-3011240b6ea6"},"name":"test-nodejs","namespace":"nuclio"},"spec":{"build":{"codeEntryType":"sourceCode","commands":["npm install --global moment"],"functionSourceCode":"[redacted]","registry":"localhost:5000"},"description":"Uses moment.js (which is installed as part of the build) to add a specified amount of time to "now", and returns this amount as a string.
","handler":"handler","maxReplicas":1,"minReplicas":1,"platform":{},"resources":{},"runtime":"nodejs"}}}]
[00:12:07.620] (I) Function deploy complete [httpPort: 30372]
```

Test de la fonction :boom: :

``` json
{
  "error": "Failed to invoke function"
}
```

Pas mieux en simplifiant le code de la fonction. Fin.

## 28 oct. 2018

Même procédure complète (pour redémarrer un cluster Kubernetes tout neuf, déployer Nuclio dessus, etc.) et cette fois, le deploy/test de fonctions passe nickel depuis le dashboard.

Test de deploy/invoke en ligne de commande : nickel aussi.

Première tentative d'écrire un Dockerfile pour gérer un runtime (ici PHP) acceptant son code source via le trigger (body HTTP requête POST), en suivant https://nuclio.io/docs/latest/tasks/deploy-functions-from-dockerfile/.

``` sh
docker build -t codering/test-php-simple .
nuctl deploy test-php-simple --run-image codering/test-php-simple:latest --runtime shell --handler "proxy-function.sh" --platform local
```