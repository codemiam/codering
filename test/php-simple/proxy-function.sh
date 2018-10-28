#!/bin/sh

# General-purpose handler for PHP RPC.
# TODO: run php to eval code payload
#
# https://github.com/nuclio/nuclio/issues/280
# https://github.com/nuclio/nuclio/blob/master/docs/reference/runtimes/shell/writing-a-shell-function.md
#
# @nuclio.configure
#
# function.yaml:
#   apiVersion: "nuclio.io/v1"
#   kind: "Function"
#   metadata:
#     name: test-php-simple
#     namespace: nuclio
#   spec:
#     runtime: "shell"
#     handler: "proxy-function.sh"

echo "Script called with $@"
# TODO: leverage php binary to run/eval user's source code received as input