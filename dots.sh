#!/bin/bash

( while : ; do sleep 300000 ; echo -n . ; done ) &
$@
