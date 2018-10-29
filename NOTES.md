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

Et ça plante, "Function wasn't ready in time" etc.

Ok, donc je me suis dit que cette option `--platform local` est bizarre, normalement je veux agir au sein du cluster k8s donc ce serait plutôt `--platform kube` (ou rien, car `auto`). Mais dans ce cas, la commande `nuctl deploy` plante en disant que l'image n'est pas pullable.

Je pense donc qu'il faut héberger l'image dans le registry qui tourne au sein du cluster k8s :

``` sh
docker image tag codering/test-php-simple:latest $(minikube ip):5000/codering/test-php-simple
# pas d'output, mais ok.
```

``` sh
docker push $(minikube ip):5000/codering/test-php-simple
89cb6417a5c4: Pushed
43b89b4e6fa6: Pushed
478c05496cf0: Pushed
d639c1323ea3: Pushed
f1aefe9f02bb: Pushed
861b714cd9d5: Pushed
d73042a7a71a: Pushed
75203553d20b: Pushed
82c67d0a2ab7: Pushed
51dcf0366b9d: Pushed
ae1a20d1ae91: Pushed
df64d3292fd6: Pushed
latest: digest: sha256:74236d1a5d7e5ab37b4d3c6e87340abc120a6b52a0327611f3cb707a4d3a5f47 size: 2828
```

Bien, nouvelle tentative avec

``` sh
nuctl deploy test-php-simple --run-image codering/test-php-simple:latest --runtime shell --handler "proxy-function.sh" --namespace nuclio --registry $(minikube ip):5000 --run-registry localhost:5000
```

Mais ça plante :

``` txt
nuctl deploy test-php-simple --run-image codering/test-php-simple:latest --runtime shell --handler "proxy-function.sh" --namespace nuclio --registry $(minikube ip):5000 --run-registry localhost:5000
18.10.28 21:40:13.933                     nuctl (I) Deploying function {"name": "test-php-simple"}
818.10.28 21:40:46.089                     nuctl (W) Create function failed failed, setting function status {"err": "Failed to wait for function readiness.\n\nPod logs:\n\n* test-php-simple-866c5bd44-2vw2n\n18.1
0.28 20:40:39.406 \u001b[37m                processor\u001b[0m \u001b[33m(W)\u001b[0m Platform configuration not found, using defaults {\"path\": \"\"}\n18.10.28 20:40:39.406 \u001b[37m                processor\
u001b[0m \u001b[32m(D)\u001b[0m Read platform configuration {\"config\": {\"webAdmin\":{\"enabled\":true,\"listenAddress\":\":8081\"},\"healthCheck\":{\"enabled\":true,\"listenAddress\":\":8082\"},\"logger\":{\"
sinks\":{\"stdout\":{\"kind\":\"stdout\"}},\"system\":[{\"level\":\"debug\",\"sink\":\"stdout\"}],\"functions\":[{\"level\":\"debug\",\"sink\":\"stdout\"}]},\"metrics\":{}}}\n\nError - open : no such file or dir
ectory\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n\nCall stack:\nFailed to open configuration file\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n\n\n* test-php-simple-f8b9bbcc8-t9464
\n18.10.28 20:40:00.291 \u001b[37m                processor\u001b[0m \u001b[33m(W)\u001b[0m Platform configuration not found, using defaults {\"path\": \"\"}\n\nError - open : no such file or directory\n    .../
nuclio/nuclio/cmd/processor/app/processor.go:223\n\nCall stack:\nFailed to open configuration file\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n18.10.28 20:40:00.291 \u001b[37m                proce
ssor\u001b[0m \u001b[32m(D)\u001b[0m Read platform configuration {\"config\": {\"webAdmin\":{\"enabled\":true,\"listenAddress\":\":8081\"},\"healthCheck\":{\"enabled\":true,\"listenAddress\":\":8082\"},\"logger\
":{\"sinks\":{\"stdout\":{\"kind\":\"stdout\"}},\"system\":[{\"level\":\"debug\",\"sink\":\"stdout\"}],\"functions\":[{\"level\":\"debug\",\"sink\":\"stdout\"}]},\"metrics\":{}}}\n\n", "errVerbose": "\nError - F
unction in error state (\nError - context deadline exceeded\n    .../pkg/platform/kube/controller/function.go:112\n\nCall stack:\nFailed to wait for function resources to be available\n    .../pkg/platform/kube/
controller/function.go:112\n)\n    .../nuclio/nuclio/pkg/platform/kube/deployer.go:178\n\nCall stack:\nFunction in error state (\nError - context deadline exceeded\n    .../pkg/platform/kube/controller/function.
go:112\n\nCall stack:\nFailed to wait for function resources to be available\n    .../pkg/platform/kube/controller/function.go:112\n)\n    .../nuclio/nuclio/pkg/platform/kube/deployer.go:178\nFailed to wait forf
unction readiness.\n\nPod logs:\n\n* test-php-simple-866c5bd44-2vw2n\n18.10.28 20:40:39.406 \u001b[37m                processor\u001b[0m \u001b[33m(W)\u001b[0m Platform configuration not found, using defaults {\
"path\": \"\"}\n18.10.28 20:40:39.406 \u001b[37m                processor\u001b[0m \u001b[32m(D)\u001b[0m Read platform configuration {\"config\": {\"webAdmin\":{\"enabled\":true,\"listenAddress\":\":8081\"},\"h
ealthCheck\":{\"enabled\":true,\"listenAddress\":\":8082\"},\"logger\":{\"sinks\":{\"stdout\":{\"kind\":\"stdout\"}},\"system\":[{\"level\":\"debug\",\"sink\":\"stdout\"}],\"functions\":[{\"level\":\"debug\",\"s
ink\":\"stdout\"}]},\"metrics\":{}}}\n\nError - open : no such file or directory\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n\nCall stack:\nFailed to open configuration file\n    .../nuclio/nuclio
/cmd/processor/app/processor.go:223\n\n\n* test-php-simple-f8b9bbcc8-t9464\n18.10.28 20:40:00.291 \u001b[37m                processor\u001b[0m \u001b[33m(W)\u001b[0m Platform configuration not found, using defau
lts {\"path\": \"\"}\n\nError - open : no such file or directory\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n\nCall stack:\nFailed to open configuration file\n    .../nuclio/nuclio/cmd/processor/a
pp/processor.go:223\n18.10.28 20:40:00.291 \u001b[37m                processor\u001b[0m \u001b[32m(D)\u001b[0m Read platform configuration {\"config\": {\"webAdmin\":{\"enabled\":true,\"listenAddress\":\":8081\"
},\"healthCheck\":{\"enabled\":true,\"listenAddress\":\":8082\"},\"logger\":{\"sinks\":{\"stdout\":{\"kind\":\"stdout\"}},\"system\":[{\"level\":\"debug\",\"sink\":\"stdout\"}],\"functions\":[{\"level\":\"debug\
",\"sink\":\"stdout\"}]},\"metrics\":{}}}\n\n\n    .../nuclio/nuclio/pkg/platform/kube/deployer.go:150\nFailed to wait for function readiness.\n\nPod logs:\n\n* test-php-simple-866c5bd44-2vw2n\n18.10.28 20:40:39
.406 \u001b[37m                processor\u001b[0m \u001b[33m(W)\u001b[0m Platform configuration not found, using defaults {\"path\": \"\"}\n18.10.28 20:40:39.406 \u001b[37m                processor\u001b[0m \u00
1b[32m(D)\u001b[0m Read platform configuration {\"config\": {\"webAdmin\":{\"enabled\":true,\"listenAddress\":\":8081\"},\"healthCheck\":{\"enabled\":true,\"listenAddress\":\":8082\"},\"logger\":{\"sinks\":{\"st
dout\":{\"kind\":\"stdout\"}},\"system\":[{\"level\":\"debug\",\"sink\":\"stdout\"}],\"functions\":[{\"level\":\"debug\",\"sink\":\"stdout\"}]},\"metrics\":{}}}\n\nError - open : no such file or directory\n.../n
uclio/nuclio/cmd/processor/app/processor.go:223\n\nCall stack:\nFailed to open configuration file\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n\n\n* test-php-simple-f8b9bbcc8-t9464\n18.10.28 20:40:
00.291 \u001b[37m                processor\u001b[0m \u001b[33m(W)\u001b[0m Platform configuration not found, using defaults {\"path\": \"\"}\n\nError - open : no such file or directory\n    .../nuclio/nuclio/cmd
/processor/app/processor.go:223\n\nCall stack:\nFailed to open configuration file\n    .../nuclio/nuclio/cmd/processor/app/processor.go:223\n18.10.28 20:40:00.291 \u001b[37m                processor\u001b[0m \u0
01b[32m(D)\u001b[0m Read platform configuration {\"config\": {\"webAdmin\":{\"enabled\":true,\"listenAddress\":\":8081\"},\"healthCheck\":{\"enabled\":true,\"listenAddress\":\":8082\"},\"logger\":{\"sinks\":{\"s
tdout\":{\"kind\":\"stdout\"}},\"system\":[{\"level\":\"debug\",\"sink\":\"stdout\"}],\"functions\":[{\"level\":\"debug\",\"sink\":\"stdout\"}]},\"metrics\":{}}}\n\n", "errCauses": [{"error": "Function in error
state (\nError - context deadline exceeded\n    .../pkg/platform/kube/controller/function.go:112\n\nCall stack:\nFailed to wait for function resources to be available\n    .../pkg/platform/kube/controller/functi
on.go:112\n)", "errorVerbose": "\nError - Function in error state (\nError - context deadline exceeded\n    .../pkg/platform/kube/controller/function.go:112\n\nCall stack:\nFailed to wait for function resources
to be available\n    .../pkg/platform/kube/controller/function.go:112\n)\n    .../nuclio/nuclio/pkg/platform/kube/deployer.go:178\n\nCall stack:\nFunction in error state (\nError - context deadline exceeded\n
 .../pkg/platform/kube/controller/function.go:112\n\nCall stack:\nFailed to wait for function resources to be available\n    .../pkg/platform/kube/controller/function.go:112\n)\n    .../nuclio/nuclio/pkg/platfor
m/kube/deployer.go:178\nFunction in error state (\nError - context deadline exceeded\n    .../pkg/platform/kube/controller/function.go:112\n\nCall stack:\nFailed to wait for function resources to be available\n
   .../pkg/platform/kube/controller/function.go:112\n)", "errorCauses": [{}]}]}
18.10.28 21:40:46.089    nuctl.platform.updater (I) Updating function {"name": "test-php-simple"}

Error - Function in error state (
Error - context deadline exceeded
    .../pkg/platform/kube/controller/function.go:112
    Call stack:
Failed to wait for function resources to be available
    .../pkg/platform/kube/controller/function.go:112
)
    .../nuclio/nuclio/pkg/platform/kube/deployer.go:178

Call stack:
Function in error state (
Error - context deadline exceeded
    .../pkg/platform/kube/controller/function.go:112

Call stack:
Failed to wait for function resources to be available
    .../pkg/platform/kube/controller/function.go:112
)
    .../nuclio/nuclio/pkg/platform/kube/deployer.go:178
Failed to wait for function readiness.

Pod logs:

* test-php-simple-866c5bd44-2vw2n
18.10.28 20:40:39.406                 processor (W) Platform configuration not found, using defaults {"path": ""}
18.10.28 20:40:39.406                 processor (D) Read platform configuration {"config": {"webAdmin":{"enabled":true,"listenAddress":":8081"},"healthCheck":{"enabled":true,"listenAddress":":8082"},"logger":{"sinks":{"stdout":{"kind":"stdout"}},"system":[{"level":"debug","sink":"stdout"}],"functions":[{"level":"debug","sink":"stdout"}]},"metrics":{}}}

Error - open : no such file or directory
    .../nuclio/nuclio/cmd/processor/app/processor.go:223

Call stack:
Failed to open configuration file
    .../nuclio/nuclio/cmd/processor/app/processor.go:223


* test-php-simple-f8b9bbcc8-t9464
18.10.28 20:40:00.291                 processor (W) Platform configuration not found, using defaults {"path": ""}

Error - open : no such file or directory
    .../nuclio/nuclio/cmd/processor/app/processor.go:223

Call stack:
Failed to open configuration file
    .../nuclio/nuclio/cmd/processor/app/processor.go:223
18.10.28 20:40:00.291                 processor (D) Read platform configuration {"config": {"webAdmin":{"enabled":true,"listenAddress":":8081"},"healthCheck":{"enabled":true,"listenAddress":":8082"},"logger":{"sinks":{"stdout":{"kind":"stdout"}},"system":[{"level":"debug","sink":"stdout"}],"functions":[{"level":"debug","sink":"stdout"}]},"metrics":{}}}


    .../nuclio/nuclio/pkg/platform/kube/deployer.go:150
Failed to deploy function
    .../nuclio/pkg/platform/abstract/platform.go:128
```

---

IT WORKS!!!

@see https://github.com/nuclio/nuclio/issues/1016

``` sh
docker build --no-cache -t codering/test-php-simple .
docker tag codering/test-php-simple:latest $(minikube ip):5000/codering-test-php-simple:latest
docker push $(minikube ip):5000/codering-test-php-simple
nuctl deploy test-php-simple --run-image codering-test-php-simple:latest --runtime shell --handler "proxy-function.sh" --namespace nuclio --registry $(minikube ip):5000 --run-registry localhost:5000
nuctl invoke test-php-simple -m POST -b " <?= 11+1;"
# répond "12" :)
```

## 29 oct. 2018

Retour de @Javius sur l'issue, et bug corrigé : il fallait expliciter les chemins