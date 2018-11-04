Architecture
============

Objectif principal : exécuter du code écrit par un utilisateur, le plus rapidement possible, avec le plus de fiabilité et de sécurité possible.

## Résumé de l'archi

- client réactif ([unredux][unredux]), sources des requêtes d'exécution de code
- FaaS ([nuclio.io][nuclio]) : environnement des runtimes
- serveur : essentiellement une API pour les données semi-statiques (compte client, etc.)

Le client (codering-ui) présente une UI permettant d'écrire du code pour solutionner un exercice, et de déclencher ce code à loisir. Cette _runtime request_ émise par le client en HTTP est traitée par le FaaS (codering-x), dont le rôle est de traiter la requête en exécution le plus rapidement possible, avec la plus grande fiabilité possible. Une réponse est ensuite retournée au client, qui l'interprète (affichage du résultat du run, des tests, etc.)

## FaaS (codering-x)

codering-x est la brique logicielle chargée de gérer les runtimes des exercices (`x` comme `execute`).

> Runtime : environnement d'exécution du code. Ex. Node.js 8, PHP 7, etc.

Il s'agit d'un FaaS (nuclio.io), _Function as a Service_. Schématiquement, un bout de code écrit par un utilisateur de la plateforme est envoyé par un client au serveur FaaS, qui l'exécute au sein du runtime approprié, la réponse étant récupérée et traitée par le client ayant initié le processus d'exécution du code. Du point de vue de ce client, le FaaS se comporte comme une API Web classique.

Coté serveur/FaaS, chaque demande d'exécution d'un runtime déclenche le travail d'un _function worker_, éventuellement scalé sur un cluster kubernetes pour paralléliser les traitements de requêtes concurrentes et indépendantes (_load balancing_ automatique).

Pour créer ce _function worker_, le FaaS se base sur un _function artifact_ ; dans le cas de codering-x, il s'agit d'une image docker préparée par avance, contenant un runtime spécifique et toutes autres dépendances d'exécution. Lorsqu'un bout de code doit être exécuté dans son runtime, un (ou plusieurs) worker est (sont) créé(s), sous la forme d'un container. Le container se comporte comme une fonction : des paramètres en entrée (bout de code à exécuter, contexte, ARGS…), un corps de fonction (script écrit dans le langage du runtime), une valeur de retour.

Idéalement, chaque requête est traitée par au moins deux _function workers_, le plus rapide l'emporte (sa valeur de retour est utilisée comme réponse au client), sauf en cas d'erreur (auquel cas le second worker fait office de fallback, avec gestion d'un retry par respawn de worker(s) par le FaaS).

> [En local](https://nuclio.io/docs/latest/introduction/) : il n'y a pas de cluster (sauf à en monter un bien sûr), les workers sont déployés sur l'unique démon Docker local, puis exposés en HTTP sur un port random.

[nuclio]: https://nuclio.io/
[unredux]: https://github.com/ivan-kleshnin/unredux

## Création d'un runtime

L'idée est de suivre https://nuclio.io/docs/latest/tasks/deploy-functions-from-dockerfile/ pour créer un runtime par langage[:version] supporté.

On souhaite le faire pour deux raisons principales :

- support de langages et versions précises, sans dépendre des versions officielles de Nuclio
- gestion custom des environnements d'exécution des runtimes (process manager, logs, etc.)

Contrairement à un _function artifact_ classique de Nuclio, à savoir une image docker contenant le runtime (php, nodejs, etc.) et le code source (fonction à exécuter dans le runtime), dans le cas de codering-x, l'artifact ne va pas contenir code source. Le code source sera transmis en tant que payload du POST client. Le point d'entrée/exécution dans le FaaS n'est donc pas une fonction « native » (écrite dans le langage du runtime), mais une fonction proxy qui doit récupérer le payload (code source) et déclencher l'exécution de ce code source dans le runtime.

Le plus simple semble de coder cette fonction proxy en sh, et donc d'avoir une image dont le runtime (au sens Nuclio) est "shell". La fonction proxy pourrait d'ailleurs être toujours la même, quel que soit le runtime à appeler, car on peut découpler l'exécution de cette fonction proxy de la commande concrète lançant le runtime, en passant par un fichier .sh à fournir, runtime par runtime :

- Node.js v8 => proxy-function appelle runtime.sh => runtime.sh appelle "node ..."
  où ... représente le stream de code source initialement reçu par la proxy-function et envoyé à runtime.sh
- PHP 7 => proxy-function appelle runtime.sh => runtime.sh appelle "php ..."
  où ... représente (etc. pareil)

Il faut arriver à voir comment runtime.sh peut être fourni pour chaque runtime.

Il faudrait en fait faire une image onbuild pour la proxy-function, avec ONBUILD COPY runtime.sh /path/to/runtime.sh — ça permettrait d'ailleurs de gérer les options d'env (ex. activer une lib pour PHP).

- L'image proxy-function contiendrait s6 etc. tout le runtime env partagé (gestion des logs, etc.)
- L'image runtime spécifique contiendrait le runtime et ses dépendances, ainsi que runtime.sh pour exécution.

---

Une autre possibilité, c'est de faire mon propre processor (ne pas utiliser https://github.com/nuclio/nuclio/tree/master/pkg/processor/runtime/shell). En fait, ce serait l'idéal pour utiliser s6 etc.

> Il faut sécuriser à terme le runtime (même si en fait on s'en fout un peu si ça plante ou si tentative de hack, puisque l'exécution est dockerisée).

## Prototype

28 oct. 2018 : runtime PHP fonctionne avec un trigger HTTP POST. De là, il est possible de faire un prototype d'UI. Coté Docker, ce serait cool d'avoir une base run-image qui fournit alpine, bash… (pas trop de trucs). Le function-proxy.sh est à créer par runtime, donc une image par langage[:version]. On peut imaginer aller encore plus loin en générant l'image à la volée pour certains exercices dans lesquels l'élève choisit d'installer une lib externe ou d'activer un réglage par exemple.

04 nov. 2018 : passage à OpenWhisk (qui supporte CORS et globalement est plus mature sur les workflows que Nuclio). Architecture repensée : il est possible de créer des containers d'exécution du code « à la volée » (https://www.ibm.com/blogs/bluemix/2017/01/docker-bluemix-openwhisk/ & https://github.com/apache/incubator-openwhisk/blob/master/docs/actions-docker.md & fin de https://medium.com/openwhisk/serverless-functions-in-your-favorite-language-with-openwhisk-f7c447558f42 — les articles viennent de https://rabbah.io/).

L'idée est de stocker les specs d'un exercice en bdd, et lors d'une demande d'exécution, de créer le container runtime à la volée (réutilisable ensuite en warm start). Concrètement, il faut packager le code (specs) + un script exec dans un .zip, puis créer une action OpenWhisk à la volée avec ce .zip, sur la base d'une image docker de base type openwhisk/dockerskeleton — avec le script exec qui dépend du runtime à utiliser (PHP, Node.js, etc.). Le code à tester vient en payload HTTP comme d'hab.

Au submit du formulaire client, on POST vers une action du type codering/system/run (en envoyant ID de l'exercice et code source à tester), action de type "conductor" qui fait le travail de récupération des specs de l'exercice + détermination du runtime à utiliser + génération d'un zip sur-mesure + création d'une action à la volée + appel de l'action (évidemment, on réutilise l'action en warm start si possible). Ce endpoint va scaler nickel sur le FaaS, l'action créée à la volée aussi, donc pas de problème. Et l'action va disparaître au bout d'un moment, ce qui donne au final un système léger et auto-nettoyant.

Ça évite d'avoir à pré-générer des images, pas besoin de les publier sur un registry Docker (sachant qu'OpenWhisk est limité à Docker Hub public pour le moment !) et ça offre la possibilité de facilement installer des dépendances supplémentaires at runtime si l'exercice le requière (composer.json & package.json, mais aussi des libs systèmes styles image-magick, etc.)

À tester : la possibilité d'utiliser une autre image de base que dockerskeleton ; il paraît (cf. article ibm.com) qu'il y a une limitation par rapport à ça, mais en fait j'en suis pas sûr, car dans l'article il faut crée les actions avec juste --docker, alors que désormais il faut --docker openwhisk/dockerskeleton explicitement => possibiilté d'utiliser une autre image ??? On pourrait à ce moment-là FROM openwhisk/dockerskeleton pour dériver les images des runtimes de ce template, de sorte à réutiliser le proxy/serveur déjà fournit dedans qui s'intègre nickel au workflow OpenWhisk (Invoker etc.).

À retenir : wsk action create foo foo.sh --native (le flag --native crée une action de --kind bash, qui est exécutée dans dockerskeleton https://github.com/apache/incubator-openwhisk/pull/3138#issuecomment-366863338) donc une solution rapide mais pas souple.

Pour optimiser les performances, un dry-run pourrait être lancé lorsque l'exercice est ouvert et que quelques caractères sont écrits dans le textarea.