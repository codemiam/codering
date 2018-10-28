#!/bin/sh

# General-purpose handler for PHP RPC.
#
# https://github.com/nuclio/nuclio/issues/280
# https://github.com/nuclio/nuclio/blob/master/docs/reference/runtimes/shell/writing-a-shell-function.md

echo "Script called with $@"



# echo "source code:"

# cat /dev/stdin



# echo "runtime response:"

# cat /dev/stdin | php
# nope, doesn't work

# php -f /dev/stdin
# nope, gotta use full path for some reason (even though PATH works fine from
# within the container)

# !!! works with either:
#   nuctl invoke -n nuclio test-php-simple -m POST -b " <?php echo 'test' ?>"
#   echo " <?= 'test';" | http POST $(minikube ip):32579
#   http POST $(minikube ip):32579 <<< " <?= 'test';"
# (notice the whitespace character before <?php, because readline reads the first
#  character of the next line, so first line gets truncated)
/usr/local/bin/php -f /dev/stdin