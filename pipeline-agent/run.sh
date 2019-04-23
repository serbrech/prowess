#!/bin/bash
set -e

dockerd &
./start-agent.sh