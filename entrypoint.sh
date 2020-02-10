#!bin/sh

set -e

if [ -z "${RESTIC_PASSWORD}" ]; then
  echo "Please provide the variable RESTIC_PASSWORD" >&2
  exit 1
fi

if [ -z "${RESTIC_TAG}" ]; then
  echo "Please provide the variable RESTIC_TAG" >&2
  exit 1
fi

if [ -n "${RESTIC_INIT}" ]; then
  echo "Initialize repository '${RESTIC_REPOSITORY}'..."
  restic init | true
fi

mkdir -p /var/spool/cron/crontabs
echo "${SCHEDULE} /usr/local/sbin/backup.sh" > /var/spool/cron/crontabs/root

exec "${@}"
