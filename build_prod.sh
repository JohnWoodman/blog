#!/bin/sh
hugo
rm -rf /var/www/html/*
rsync -av public/ /var/www/html/
