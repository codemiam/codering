# Codering

**Codering** is an automated, scalable, distributed web stack, powering an educational platform focused towards _learning how to code_.

It consists of a full-fledged platform made of loosely-coupled services that anyone can deploy on a single server, or better, a Kubernetes cluster.

The platform is _fully open-source_, featuring:

- a lightweight, reactive, allegedly nice-looking client app
- a highly-performant, distributed FaaS

Check [IDEAS.md](./IDEAS.md) (fr) for the initial vision.

## How to clone this repo

This repo is a [meta-repo](https://github.com/mateodelnorte/meta). Clone it using:

`meta git clone`

## Development

Initial setup (once):

``` sh
# Clone everything at once:
# - ./faas, the backend's core-project (runs on OpenWhisk, used as a FaaS cluster / API for codering's runtimes)
# - ./website, the frontend project
meta git pull
```

Every time you wanna work on the project:

> TODO: automate with a Makefile or npm's concurrently

``` sh
# Starting the FaaS
cd faas/docker-compose
make run
# NOTE: might fail due to incorrect host's Docker IP, see NOTES.md for a workaround.

# Starting the website
cd website
yarn start
```
