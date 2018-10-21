## But du projet

Codewars, mais en mieux et qui fonctionne sans planter.

### Description

Une plateforme d'exercices en ligne, inspiré de [Codewars](https://www.codewars.com/), mais en mieux :

- sans vocabulaire bizarre à base d'arts martiaux
- sans toutes les fonctionnalités inutiles
- sans l'UI moche et _bloated_
- sans les plantages intempestifs
- sans le moteur de recherche aberrant
- sans code de setup caché
- sans tests cachés et indebuggables
- sans soumission de la solution en deux temps
- sans [insérer ici tout ce qui déconne sur Codewars + idées de trucs à éviter]

Donc :

- avec une UI/UX simple et efficace, y compris en mode auteur (notamment, séparer les instructions de l'exercice du reste pour les avoir toujours sous les yeux, même lors du run des tests)
- avec des fonctionnalités de catégorisation, partage, suivi, favoris et guilde qui fonctionnent
- avec un système de tests clair
- avec une gestion de premier rang des séries d'exercices
- avec une archi technique solide (cf. technos ci-après)
- avec un feedback d'erreurs utiles (numéros de ligne réel, stackframe, etc.)
- avec un moteur de recherche qui juste-marche
- avec [insérer ici tout ce qui manque sur Codewars + idées nouvelles à prendre en compte]

Etc. Ansi que des pistes un peu plus techniques / chronophages :

- choix d'un profil débutant / confirmé, qui permettrait d'afficher / masquer par défaut des indices fournis par l'auteur d'un exercice (dans l'énoncé, dans le setup code) ; en conservant la possibilité de masquer / afficher à loisir
- support multilingue (UI et exercices)
- support d'options utiles dans les runtimes (par exemple, en tant qu'auteur d'exercices PHP 7, activer `declare(strict_types=1)` ou GMP)
- support de Semantic Versioning pour fixer le range de version(s) d'un runtime (surtout pour éviter les régressions d'exercices liées à des montées de versions majeures)
- mode collaboratif temps-réel (ex. WebSocket)
- support d'un mode streaming (par exemple container persistant et runtime réactif à la frappe clavier)
- notifications mail / sms sur following de contributeurs, thèmes ou séries
- mode contre-la-montre
- événements type [FFA](https://fr.wikipedia.org/wiki/Match_%C3%A0_mort) ou au contraire collaboratif sur un exercice (ou une série) donné à une heure précise
- support marque-blanche, sur runtime privé (avec ou sans accès au corpus d'exercices communautaire)

### Opportunités

* Un projet complet, extensible, ultra-qualifié, utile et riche pédagogiquement.
* Challenge technique intéressant et à forte valeur ajoutée pour entretiens d'embauche ultérieurs.
* Possibilité d'adjoindre un _business model_ pour faire tenir l'activité dans le temps et en scaling horizontal (si l'archi est bien conçue).
* Si projet open-sourcé : potentiel de contribution tiers / création d'une communauté (d'ici à passer le titre pro).

## Quelles seront/pourraient être les technologies utilisées ?

* Frontal dynamique type React, https://github.com/ivan-kleshnin/unredux
* Backend type Symfony, Elixir
* Runtime des exercices :
  * FaaS server-less type [AWS Lambda](https://aws.amazon.com/fr/lambda/) (possibilité d'auto-hébergement avec https://nuclio.io/)
  * containerisation légère dynamique type `docker run` sur base Alpine/s6 par exemple
  * voire runtime embarqué coté client si possible techniquement et anti-triche