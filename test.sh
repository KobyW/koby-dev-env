#!/bin/bash
docker build -t debian-dev-env-test .
docker run -it debian-dev-env-test
