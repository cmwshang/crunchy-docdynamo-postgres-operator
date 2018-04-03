# pgbackrest Support in Crunchy Container Suite

## Description

pgbackrest is a utility that performs a backup, restore, archive function for a PostgreSQL database. pgbackrest is written and maintained by David Steele, a fellow Crunchy Data colleague!

pgbackrest is described here:

[http://www.pgbackrest.org/](http://www.pgbackrest.org/)

New functionality for pgbackrest was added into the Crunchy Container Suite as of version 1.3.1. Backups are currently performed by manually executing pgbackrest commands against the desired pod. Restores can now be performed via a new crunchy-backrest-restore container, which offers FULL or DELTA restore capability.

This document will discuss the design and usage of the pgbackrest features as implemented so far.

### pgbackrest Configuration

pgbackrest is configured using a pgbackrest.conf file that is mounted into the crunchy-postgres container at /pgconf.

If you place a pgbackrest.conf file within this mounted directory, it will trigger the use of pgbackrest within the PostgreSQL container as the archive_command and will turn on the archive_mode to begin archival. You still need to define the ARCHIVE_TIMEOUT environment variable within your container configuration because it is set to a disable value of 0 by default!

The following changes will be made to the container's postgresql.conf file:
```
ARCHIVE_MODE=on
ARCHIVE_TIMEOUT=60
ARCHIVE_COMMAND='pgbackrest --stanza=db archive-push %p'
```
If you are using a postgres image older than **1.7.1**, **archive_command** must specify where the **pgbackrest.conf** file is located:
```
ARCHIVE_COMMAND='pgbackrest --config=/pgconf/pgbackrest.conf --stanza=db archive-push %p'
```
This requires you use a pgbackrest stanza name of **db** within the pgbackrest.conf file you mount.

When set, WAL files generated by the database will be written out to the /backrestrepo mount point.

### Performing a Backup

Examples for backrest have been created within the standalone, openshift, and kubernetes examples directories.

Once you configure the crunchy-postgres container to use pgbackrest, you will perform a backup using the following commands:
```
docker exec -it primary-backrest bash
/usr/bin/pgbackrest --stanza=db backup
```
Examine the contents of the mounted /backrestrepo directory to see the archive files and also the backup files.

### Running the Examples

#### Kubernetes

Start the example as follows:
```
cd $CCPROOT/examples/kube/backrest
./run.sh
```
This will create the following in your Kubernetes environment:

- A configMap named backrestconf which contains the pgbackrest.conf file 

- primary-backrest pod with pgbackrest archive enabled. An initial stanza db will be created on initialization 

- primary-backrest service 

The crunchy-pvc will be used for /pgdata, and crunchy-pvc2 for the /backrestrepo. Examine the /backrestrepo location to view the archive directory and ensure WAL archiving is working.

#### OpenShift

Start by running the example database container:
```
cd $CCPROOT/examples/openshift/backrest
./run.sh
```
This will create the following:

- PV/PVC for /pgconf and /backrestrepo volumes 

- primary database pod 

- primary service 

- configmap holding the pgbackrest.conf config file 

The archive files are written to the NFS path of /mnt/nfsfileshare/backrestrepo.

The presence of /pgconf/pgbackrest.conf is what is used to determine whether pgbackrest will be used as the archive command or not. You will need to specify the ARCHIVE_TIMEOUT environment variable as well to use this.

After you run the example, you should see archive files being written to the /backrestrepo volume (/mnt/nfsfileshare/backrestrepo).

#### Manual Backup

You can create a backup using backrest using this command within the container:
```
pgbackrest --stanza=db backup
```

### Performing a Restore

There are two options to choose from when performing a restore, DELTA and FULL. A FULL is the default; a DELTA will only occur if the environment variable DELTA is specified in the restore-job spec. Consult the pgbackrest user guide to determine which is best suited to run.

Steps for FULL restore

- Delete the primary-backrest pod, if still running using 

- Empty the PGDATA directory (remove all files) 

- Navigate to the backrest-restore examples directory. Execute the full-restore.sh script. 

- Check the restore logs (db-restore.log) in the /backrestrepo mountpointfor success. You can also view the logs of the completed job pod with kubectl get pod -a 

- Re-create the primary-backrest pod in the backrest examples directory. The database will recover. 

Steps for DELTA restore

- Delete the primary-backrest pod, if still running 

- rm postmaster.pid from PGDATA. 

- Navigate to the backrest-restore examples directory. Execute the delta-restore.sh script. 

- Check the restore logs (db-restore.log) in the /backrestrepo mountpointfor success. You can also view the logs of the completed job pod with kubectl get pod -a 

- Re-create the primary-backrest pod in the backrest examples directory. The database will recover only files that have changed from the last backup.

## Legal Notices

Copyright &copy; 2018 Crunchy Data Solutions, Inc.

CRUNCHY DATA SOLUTIONS, INC. PROVIDES THIS GUIDE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

Crunchy, Crunchy Data Solutions, Inc. and the Crunchy Hippo Logo are trademarks of Crunchy Data Solutions, Inc.