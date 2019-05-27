#!/bin/bash

/usr/local/sbin/nginx -g 'daemon on; master_process on;'
FLASK_APP=server.py flask run
