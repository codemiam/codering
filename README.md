# Codering

**Codering** is an automated, scalable, distributed web stack, powering an educational platform focused towards _learning how to code_.

It consists of a full-fledged platform made of loosely-coupled services that anyone can deploy on a single server, or better, a Kubernetes cluster.

The platform is _fully open-source_, featuring:

- a lightweight, reactive, allegedly nice-looking client app
- a highly-performant, distributed FaaS

Check [IDEAS.md](./IDEAS.md) (fr) for the initial vision.

## How to work within this repo

This repo is a [meta-repo](https://github.com/mateodelnorte/meta) (install it). It acts as a "box" for all of codering's project. Clone it with:

`git clone https://github.com/codemiam/codering.git`

You end up with a local codering/ folder. Step inside, then clone all the sub-projects at once with:

`meta git clone`

It will populate sub-folders such as faas/ and website/ with their respective code. Now let's hack!

## Development

Initial setup (once):

``` sh
# Clone everything at once:
# - ./faas, the backend's core-project (runs on OpenWhisk, used as a FaaS cluster / API for codering's runtimes)
# - ./website, the frontend project
meta git clone # as explained in the previous section
```

Every time you wanna work on codering:

``` sh
# Sync all projects
meta git pull

# Start the FaaS cluster
cd faas/docker-compose
make run
# NOTE: might fail due to incorrect host's Docker IP, see NOTES.md for a workaround.

# Start the website
cd website
yarn start # Head to http://localhost:3000/
```

> TODO: automate with a Makefile or npm's concurrently, providing a data seed for the cluster.
> TODO: make the data seed persistent.
