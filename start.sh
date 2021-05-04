#!/bin/bash

docker run -dti \
    --name=syncer \
    -v repos:/repos \
    --log-opt max-size=1m \
    --log-opt max-file=9 \
    --restart=unless-stopped \
    private/syncer
