#!/bin/bash

date=$(date +"%Y.%m.%d-%H:%M")

git pull
git add -A .
git commit -m ${date}
git push

