#!/bin/bash

set -euxo pipefail

bucket_name="xxxxxxxxxxxxxx"                  # name of s3 bucket
container_id="xxxxxxxxxxxx"                   # api container id
project_name="xxxxxxxxxxxx"                   # project_name [My Site]: from "invenio-cli init rdm -c <version>"

docker_bin=$(which docker)
aws_bin=$(which aws)


# copy file inside contaienr to host

$docker_bin cp $container_id:/opt/$project_name/var/instance/static /tmp/

# upload to s3

$aws_bin s3 cp --recursive /tmp/static/ s3://$bucket_name/static

rm -r /tmp/static/

echo "Done."
