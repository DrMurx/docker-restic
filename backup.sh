#!/bin/sh

DATA_VOLUME="/data"

function dumpMysql() {
  mkdir -p ${DATA_VOLUME}/database

  DUMP_FILE=${DATA_VOLUME}/database/mysql_${MYSQL_HOST}_${MYSQL_DATABASE}.sql
  echo "$(date +'%Y-%m-%d %H:%M:%S') Dump MySQL/MariaDB to ${DUMP_FILE}"

  mysqldump -h ${MYSQL_HOST} \
            -P ${MYSQL_PORT:-3306} \
            -u ${MYSQL_USER:-root} \
            -p${MYSQL_PASSWORD} \
            --single-transaction \
            ${MYSQL_DATABASE} \
            > ${DUMP_FILE}.tmp || exit 1

  if [ ! -e ${DUMP_FILE} ] || ! diff ${DUMP_FILE}.tmp ${DUMP_FILE} >/dev/null; then
    mv -f ${DUMP_FILE}.tmp ${DUMP_FILE}
    echo "  done"
  else
    rm ${DUMP_FILE}.tmp
    echo "  No changes to previous dump, skipping..."
  fi
}


function dumpPostgresql() {
  mkdir -p ${DATA_VOLUME}/database

  DUMP_FILE=${DATA_VOLUME}/database/pg_${POSTGRES_HOST}_${POSTGRES_DATABASE}.sql
  echo "$(date +'%Y-%m-%d %H:%M:%S') Dump Postgres to ${DUMP_FILE}"

  PGPASSWORD=${POSTGRES_PASSWORD} \
    pg_dump -h ${POSTGRES_HOST} \
            -p ${POSTGRES_PORT:-5432} \
            -U ${POSTGRES_USER:-postgres} \
            -f ${DUMP_FILE}.tmp \
            ${POSTGRES_DATABASE} || exit 1

  if [ ! -e ${DUMP_FILE} ] || ! diff ${DUMP_FILE}.tmp ${DUMP_FILE} >/dev/null; then
    mv -f ${DUMP_FILE}.tmp ${DUMP_FILE}
    echo "  done"
  else
    rm ${DUMP_FILE}.tmp
    echo "  No changes to previous dump, skipping..."
  fi
}


echo "$(date +'%Y-%m-%d %H:%M:%S') Preparing backup"

[[ -n "${MYSQL_HOST}"    && -n "${MYSQL_DATABASE}" ]]    && dumpMysql
[[ -n "${POSTGRES_HOST}" && -n "${POSTGRES_DATABASE}" ]] && dumpPostgresql
[[ -n "${BACKUP_BEFORE_COMMAND}" ]] && eval "${BACKUP_BEFORE_COMMAND}"

echo "$(date +'%Y-%m-%d %H:%M:%S') Starting backup"

if restic backup ${DATA_VOLUME} ${RESTIC_JOB_ARGS} --tag=${RESTIC_TAG} | cat; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') Backup finished successfully"
else
  echo "$(date +'%Y-%m-%d %H:%M:%S') Backup failed (status $?)"
  restic unlock | cat
  exit 1
fi


if [ -n "${RESTIC_FORGET_ARGS}" ]; then
  echo "$(date +'%Y-%m-%d %H:%M:%S') Expiring old snapshots"
  if restic forget ${RESTIC_FORGET_ARGS} | cat; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') Snapshots expired successfully"
    if [ -f /root/.restic-prune-on-next-run ]; then
      restic prune
      rm -v /root/.restic-prune-on-next-run
    fi
  else
    echo "$(date +'%Y-%m-%d %H:%M:%S') Expiring snapshots failed (status $?)"
    restic unlock | cat
  fi
fi
