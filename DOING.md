Installation de Minikube pour tester l'install distribube de nuclio.
Si tout va bien, création d'une image Docker pour gérer ça automatiquement, à intégrer dans docker-compose.yml (en prod, le cluster sera géré différement, par une distribution k8s).

À venir :
- tester de déployer une fonction sur le cluster Nuclio
- tester d'utiliser la fonction déployée (pb potentiel : comment connaître le endpoint dynamiquement créé par Nuclio ?)