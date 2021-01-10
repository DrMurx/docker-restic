# Usage

```
volumes:
  backup:

services:
  backup:
    image: drmurx/docker-restic-prefab
    volumes:
      - /my/folder/to/backup:/data/folder1:ro
      - /another/folder/to/backup:/data/folder2:ro
      - backup:/root/.cache/restic
    environment:
      # Backup every day at midnight
      SCHEDULE: "0 0 * * *"
      # Prune once a month after the backup on the 1st day
      PRUNE_SCHEDULE: "0 0 1 * *"
      # Your restic repository
      RESTIC_REPOSITORY: ...
      RESTIC_PASSWORD: ...
      RESTIC_TAG: default
      # Expire your backups like this
      RESTIC_FORGET_ARGS: "-d 7 -w 8 -m 6 -y 2 --group-by paths,tags"
      # Additionally, dump data from this mysql container/host
      MYSQL_HOST: ...
      MYSQL_USER: ...
      MYSQL_PASSWORD: ...
      MYSQL_DATABASE: ...
```

