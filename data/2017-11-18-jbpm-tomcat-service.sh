#!/bin/sh

TOMCAT=$(dirname $(readlink -f $0))

DATA=$TOMCAT/kie-data

export M2_HOME=$DATA/m2

case $1 in
	start)
		mkdir -p $DATA
		cd $DATA
		$TOMCAT/bin/startup.sh
		;;
	stop)
		$TOMCAT/bin/shutdown.sh
		;;
	clean)
		rm -rf kie-data logs/* temp/* work/*
		dropdb -h localhost kie
		createdb -h localhost kie
		;;
	*)
		echo "Unknown command"
		;;
esac
