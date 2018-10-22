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