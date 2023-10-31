#!/bin/bash

set -euxo pipefail

bucket_name="invenio-static-data"                  # name of s3 bucket
container_id="02840bb395ed"                   # api container id

docker_bin=$(which docker)
aws_bin=$(which aws)


# copy file inside contaienr to host

$docker_bin cp $container_id:/opt/invenio/var/instance/static /tmp/

# upload to s3

$aws_bin s3 cp --recursive /tmp/static/ s3://$bucket_name/static

rm -r /tmp/static/

echo "Done."
