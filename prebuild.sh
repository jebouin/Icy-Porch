#!/bin/bash

for f in ./*.php; do php $f > ${f%.php}.hxml; done