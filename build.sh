#!/bin/sh

node scripts/buildClient.js
cd build
rm Atlas.nw
zip -rq Atlas.nw * 
open Atlas.nw