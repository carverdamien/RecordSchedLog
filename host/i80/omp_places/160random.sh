#!/bin/bash
for i in {0..159}; do echo "{$i}"; done | sort -R | tr -d '\n' | sed 's/}{/},{/g'
