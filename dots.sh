#!/bin/bash

( while : ; do sleep 300 ; echo -n . ; done ) &
$@
