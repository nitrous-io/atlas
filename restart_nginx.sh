#!/bin/bash

kill `cat logs/nginx.pid`
nginx -p `pwd`/ -c conf/nginx.conf
