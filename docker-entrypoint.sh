#!/bin/bash

echo "Running supervisord"
supervisord

/bin/bash # Wait, dont exit to see what happened