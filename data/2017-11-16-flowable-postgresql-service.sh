#!/bin/sh

HOST=localhost

export PGDATA="$(dirname "$(readlink -f "$0")")/data"

case $1 in
    init-cluster)
        pg_ctl init
        cat >>"$PGDATA/postgresql.conf" <<EOF
listen_addresses = '$HOST'
logging_collector = on
unix_socket_directories = '.'
EOF
        pg_ctl start
        ;;
    init-database)
        createdb -h $HOST flowable
        createdb -h $HOST flowableadmin
        createdb -h $HOST flowableidm
        createdb -h $HOST flowablemodeler
        createuser -h $HOST -P flowable
        psql -h $HOST -c "GRANT ALL ON DATABASE flowable TO flowable" postgres
        psql -h $HOST -c "GRANT ALL ON DATABASE flowableadmin TO flowable" postgres
        psql -h $HOST -c "GRANT ALL ON DATABASE flowableidm TO flowable" postgres
        psql -h $HOST -c "GRANT ALL ON DATABASE flowablemodeler TO flowable" postgres
        ;;
    shell)
        psql -h $HOST postgres
        ;;
    start)
        pg_ctl start
        ;;
    stop)
        pg_ctl stop
        ;;
    *)
        echo "Unknown command"
        ;;
esac

