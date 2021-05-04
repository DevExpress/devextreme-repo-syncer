#!/bin/bash

echo "Waiting for container to finish - DO NOT INTERRUPT!"
docker logs -f --tail 0 syncer &
docker stop -t 3600 syncer
docker rm syncer
