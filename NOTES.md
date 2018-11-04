## OpenWhisk

### Host machine's Docker daemon's IP

[OpenWhisk](https://github.com/apache/incubator-openwhisk) is used as the main "[serverless backend](https://martinfowler.com/articles/serverless.html)" for the application.

In development, it [runs on Docker Compose](https://github.com/apache/incubator-openwhisk-devtools) as a collection of interleaved containers. The stack needs to know about the host's docker IP, and it may fail at discovering the IP, resulting in network errors upon running `make run`.

To fix that, edit Makefile to hard-code your docker host's IP as `DOCKER_HOST` (eg. 172.17.0.1 or similar).

> Note that one may force the IP using `DOCKER_HOST` on the host machine, [as documented about `dockerd`](https://docs.docker.com/engine/reference/commandline/dockerd/#examples).

### Useful debugging commands

#### Requests to /namespaces

Requests to the /api/v1/namespaces/ path require authentication. Use the AUTH credentials found in ~/.wskprops (or get them with `wsk -i property get --auth`). Or use this automation command (example):

``` sh
curl -k -u $(cat ~/.wskprops | awk -F "=" '/AUTH=/ {print $2}') https://172.17.0.1/api/v1/namespaces/guest/actions
```

#### Requestst to web actions

No need for credentials, as long as `wsk` is configured to work with the running OpenWhisk instance as it should:

``` sh
# Let's say there's a /guest/greeting web action:
curl -k "https://172.17.0.1/api/v1/web/guest/default/greeting.json?name=jd&place=the%20forest"
```

### Data seed

> There's no proper data seed for now, in the meantime instructions below provide some guidance into managing actions.

Following along [the official documentation](https://github.com/apache/incubator-openwhisk/blob/master/docs/actions.md), start with some code, saved (anywhere) as greeting.js:

``` js
/**
 * @params is a JSON object with optional fields "name" and "place".
 * @return a JSON object containing the message in a field called "msg".
 */
function main(params) {
  // log the paramaters to stdout
  console.log('params:', params);

  // if a value for name is provided, use it else use a default
  var name = params.name || 'stranger';

  // if a value for place is provided, use it else use a default
  var place = params.place || 'somewhere';

  // construct the message using the values for name and place
  return {msg:  'Hello, ' + name + ' from ' + place + '!'};
}
```

Turn the code into a web action on the FaaS cluster:

``` sh
wsk -i action create greeting greeting.js --web true

# It should be referenced by:
curl -k -u $(cat ~/.wskprops | awk -F "=" '/AUTH=/ {print $2}') https://172.17.0.1/api/v1/namespaces/guest/actions

# You can trigger it:
curl -k https://172.17.0.1/api/v1/web/guest/default/greeting.json
curl -k "https://172.17.0.1/api/v1/web/guest/default/greeting.json?name=Giant&place=the%20Forest"
```