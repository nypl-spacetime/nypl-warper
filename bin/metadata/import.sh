#!/bin/bash
DB=$1
shift
for i in $@; do 
    echo "loading $i"
    echo "copy raw_metadata from '$(pwd)/$i' with csv;" | psql $DB
done
psql $DB <import.sql
