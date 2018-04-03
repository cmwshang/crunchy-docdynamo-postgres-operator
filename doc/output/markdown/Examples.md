# Examples & Use Cases - Crunchy Containers for PostgreSQL

## Usage

Here are some useful resources for finding the right commands to troubleshoot & modify containers in the various environments shown in this guide:

- [Docker Cheat Sheet](http://www.bogotobogo.com/DevOps/Docker/Docker-Cheat-Sheet.php) 

- [Kubectl Cheat Sheet](https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/) 

- [OpenShift Cheat Sheet](https://github.com/nekop/openshift-sandbox/blob/master/docs/command-cheatsheet.md) 

- [Helm Cheat Sheet](https://github.com/kubernetes/helm/blob/master/docs/using_helm.md)

### Docker Customized Configuration

You can use your own version of the setup.sql SQL file to customize the initialization of database data and objects when the container and database are created.

This example can be run as follows:
```
cd $CCPROOT/examples/docker/custom-setup
./run.sh
```
This works by placing a file named, setup.sql, within the /pgconf mounted volume directory. Portions of the setup.sql file are required for the crunchy container to work, see comments within the sample setup.sql file.

#### Custom Configuration

This example shows how you can use your own customized version of setup.sql when creating a PostgreSQL database container in Kubernetes.

If you mount a /pgconf volume, crunchy-postgres will look at that directory for postgresql.conf, pg_hba.conf, and setup.sql. If it finds one of them it will use that file instead of the default files. Currently, if you specify a postgresql.conf file, you also need to specify a pg_hba.conf file.

The example shows how a custom setup.sql file can be used. Run it as follows:
```
cd $CCPROOT/examples/kubernetes/custom-config
./run.sh
```
This will start a database container that will use an NFS mounted /pgconf directory that will contain the custom setup.sql file found in the example directory.

#### Custom Configuration

This example shows how you can use your own customized version of setup.sql when creating a PostgreSQL database container in OpenShift.

If you mount a /pgconf volume, crunchy-postgres will look at that directory for postgresql.conf, pg_hba.conf, and setup.sql. If it finds one of them it will use that file instead of the default files. Currently, if you specify a postgresql.conf file, you also need to specify a pg_hba.conf file.

The example shows how a custom setup.sql file can be used. Run it as follows:
```
cd $CCPROOT/examples/openshift/custom-config
./run.sh
```
This will start a database container that will use an NFS mounted /pgconf directory that will contain the custom setup.sql file found in the example directory.

##### Customized Configuration with Synchronous Replica

This example shows how you can use your own customized version of postgresql.conf and pg_hba.conf to override the default configuration. It also specifies a synchronous replica in the postgresql.conf and starts it up upon creation.

Run it as follows:
```
cd $CCPROOT/examples/openshift/custom-config-sync
./run.sh
```
This will start a **csprimary** container that will use the custom config files when the database is running. It will also create a synchronous replica named **cssyncreplica**. This replica is then connected to the primary via streaming replication.

##### Configmap Database Credentials

This example shows how to use a configmap to store the postgresql.conf and pg_hba.conf files to be used when overriding the default configuration within the container.

Start by running the database container:
```
cd $CCPROOT/examples/openshift/configmap
./run.sh
```
The files pg_hba.conf and postgresql.conf in the example directory are used to create a configmap object within OpenShift. Within the run.sh script, the configmap is created. Notice within the configmap.json file how the /pgconf mount is related to the configmap.

##### Templates Configuration

An example of using OpenShift Templates to build pods, routes, services, etc can be found in the following directory:
```
$CCPROOT/examples/openshift/workshop
```
You use the **oc new-app** command to create objects from the JSON templates. This is an alternative way to create OpenShift objects instead of using **oc create**.

See the README file within the workshop directory for instructions on running the example.

##### Secrets

You can use Kubernetes Secrets to set and maintain your database credentials. Secrets requires you base64 encode your user and password values as follows:
```
echo -n 'myuserid' | base64
```
You will paste these values into your JSON secrets files for values.

This example allows you to set the PostgreSQL passwords using Kubernetes Secrets.

The secret uses a base64 encoded string to represent the values to be read by the container during initialization. The encoded password value is **password**. Run the example as follows:
```
cd $CCPROOT/examples/openshift/secret
./run.sh
```
The secrets are mounted in the **/pguser**, **/pgprimary**, **/pgroot** volumes within the container and read during initialization. The container scripts create a PostgreSQL user with those values, and sets the passwords for the primary user and PostgreSQL superuser using the mounted secret volumes.

When using secrets, you do NOT have to specify the following environment variables if you specify all three secrets volumes:

- PG_USER 

- PG_PASSWORD 

- PG_ROOT_PASSWORD 

- PG_PRIMARY_USER 

- PG_PRIMARY_PASSWORD 

You can test the container as follows, in all cases, the password is **password**:
```
psql -h secret-pg -U pguser1 postgres
psql -h secret-pg -U postgres postgres
psql -h secret-pg -U primary postgres
```
Secrets requires you base64 encode your user and password values as follows:
```
echo -n 'myuserid' | base64
```
You can paste these values into your JSON secrets files for values.

##### SSL Authentication

This example shows how you can configure PostgreSQL to use SSL for client authentication.

The example requires SSL keys to be created and the example script **keys.sh** is required to be executed to create the required server and client certificates. This script also creates a client key configuration you can use to test with.

The example requires an NFS volume, /pgconf, be mounted into which the PostgreSQL configuration files and keys are copied to. Permissions of the keys are important as well, they will need to be owned by either the **root** or **postgres** user. The **run.sh** script copies the required files and sets these permissions when executing the example.

The **keys.sh** script creates a client cert with the **testuser** specified as the CN. The **testuser** PostgreSQL user is created by the **setup.sql** configuration script as normal. It is with the **testuser** role that you will test with.

Run the PostgreSQL example as follows:
```
cd $CCPROOT/examples/openshift/customer-config-ssl
./run.sh
```
A required step to make this example work is to define in your **/etc/hosts** file an entry that maps **server.crunchydata.com** to the example's service IP address, this is because we generate a server certificate with the server name of **server.crunchyhdata.com**.

For example, if your service has an address as follows:
```
oc get service
NAME                CLUSTER-IP       EXTERNAL-IP   PORT(S)                   AGE
custom-config-ssl   172.30.211.108   <none>        5432/TCP
```
Then your **/etc/hosts** file needs an entry like this:
```
172.30.211.108 server.crunchydata.com
```
For a production Openshift installation, you'll likely want DNS names to resolve to the PostgreSQL Service name and generate server certificates using the DNS names instead of an example name like **server.crunchydata.com**.

Once the container starts up, you can test the SSL connection as follows:
```
psql -h server.crunchydata.com -U testuser userdb
```
You should see a connection that looks like the following:
```
psql (9.6.8)
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

userdb=>
```

#### Tips

##### PostgreSQL Passwords

The passwords used for the PostgreSQL user accounts are generated by the OpenShift _process_ command. To inspect what value was supplied, you can inspect the primary pod as follows:
```
oc get pod pr-primary -o json | grep PG
```
Look for the values of the environment variables:

- PG_USER 

- PG_PASSWORD 

- PG_DATABASE

##### Password Management

When you backup a database, the original user IDs and password credentials are copied over from the original database and saved. Because of this, you cannot use generated passwords as the new passwords will not be the same as the passwords stored in the backup.

You have various options to deal with managing your passwords:

- externalize your passwords using secrets instead of using generated values 

- manually update your passwords to your known values after a restore 
> **NOTE:**
> Environment variables can be modified when there is a a deployment controller in use. Currently, only the replicas have a deployment controller in order to avoid the possibility of creating multiple primaries.
```
oc env dc/pg-primary-rc PG_PRIMARY_PASSWORD=foo PG_PRIMARY=user1
```

##### Examine Backup Logs

Database backups are implemented as a Kubernetes Job. These are meant to run one time only and not be restarted by Kubernetes. To view jobs in OpenShift you enter:
```
oc get jobs
oc describe job backupjob
```
You can get detailed logs by referring to the pod identifier in the job _describe_ output as follows:
```
oc logs backupjob-pxh2o
```

##### Backups

Backups require the use of network storage like NFS in OpenShift. There is a required order of using NFS volumes in the manner we do database backups.

There is a one-to-one relationship between a PV (persistent volume) and a PVC (persistence volume claim). You can NOT have a one-to-many relationship between PV and PVC(s).

So, to do a database backup repeatedly, this general pattern will need to be followed.

- as OpenShift admin user, create a unique PV (e.g. backup-pv-mydatabase) 

- as a project user, create a unique PVC (e.g. backup-pvc-mydatabase) 

- reference the unique PVC within the backup-job template 

- execute the backup job template 

- as a project user, delete the job 

- as a project user, delete the PVC 

- as OpenShift admin user, delete the unique PV 

This procedure will need to be scripted and executed by the devops team when performing a database backup.

##### Restores

To perform a database restore, we do the following:

- locate the NFS path to the database backup we want to restore with 

- edit a PV to use that NFS path 

- edit a PV to specify a unique label 

- create the PV 

- edit a PVC to use the previously created PV, specifying the same label used in the PV 

- edit a database template, specifying the PVC to be used for mounting to the /backup directory in the database pod 

- create the database pod 

If the /pgdata directory is blank AND the /backup directory contains a valid PostgreSQL backup, it is assumed the user wants to perform a database restore.

The restore logic will copy /backup files to /pgdata before starting the database. It will take time for the copying of the files to occur since this might be a large amount of data and the volumes might be on slow networks. You can view the logs of the database pod to measure the copy progress.

##### Log Aggregation

OpenShift can be configured to include the EFK stack for log aggregation. OpenShift Administrators can configure the EFK stack as documented here:

[https://docs.openshift.com/enterprise/3.1/install_config/aggregate_logging.html](https://docs.openshift.com/enterprise/3.1/install_config/aggregate_logging.html)

##### nss_wrapper

If an OpenShift deployment requires that random generated UIDs be supported by containers, the Crunchy containers can be modified similar to those located here to support the use of nss_wrapper to equate the random generated UIDs/GIDs by OpenShift with the postgres user.

[https://github.com/openshift/postgresql/blob/master/9.4/root/usr/share/container-scripts/postgresql/common.sh](https://github.com/openshift/postgresql/blob/master/9.4/root/usr/share/container-scripts/postgresql/common.sh)

## Container Examples

### Running a Single Database

This example starts a single PostgreSQL container and service, the most simple of examples.

The container creates a default database called **userdb**, a default user called **testuser** and a default password of **password**.

For all environments, the script additionally creates:

- A persistent volume claim 

- A container named **basic** 

- The database using predefined environment variables 

And specifically for the Kubernetes and OpenShift environments:

- A pod named **basic** 

- A service named **basic** 

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To create the example and run the container:
```
cd $CCPROOT/examples/docker/basic
./run.sh
```
Connect from your local host as follows:
```
psql -h localhost -p 12000 -U testuser -W userdb
```

#### Kubernetes

To create the example:
```
cd $CCPROOT/examples/kube/basic
./run.sh
```
Connect from your local host as follows:
```
psql -h basic -U postgres postgres
```

#### Helm

This example resides under the $CCPROOT/examples/helm directory. View the README to run this example using Helm [here](https://github.com/CrunchyData/crunchy-containers/blob/master/examples/helm/basic/README.md).

#### OpenShift

To create the example:
```
cd $CCPROOT/examples/openshift/basic
./run.sh
```
Connect from your local host as follows:
```
psql -h basic.openshift.svc.cluster.local -U testuser userdb
```

### Creating a Primary Database with PVC

The other example **basic** uses emptyDir volumes for persistence; if it is desired to create a PVC based volume to store the PostgreSQL data files for a single primary pod, run the following example:
```
cd $CCPROOT/examples/openshift/primary-pvc
./run.sh
```

### Creating a Primary / Replica Database Cluster

This example starts a primary and a replica pod containing a PostgreSQL database.

The container creates a default database called **userdb**, a default user called **testuser** and a default password of **password**.

For the Docker environment, the script additionally creates:

- A docker volume using the local driver for the primary 

- A docker volume using the local driver for the replica 

- A container named **primary** binding to port 12007 

- A container named **replica** binding to port 12008 

- A mapping of the PostgreSQL port 5432 within the container to the localhost port 12000 

- The database using predefined environment variables 

And specifically for the Kubernetes and OpenShift environments:

- emptyDir volumes for persistence 

- A pod named **primary** 

- A pod named **replica** 

- A service named **primary** 

- A service named **replica** 

- The database using predefined environment variables 

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To create the example and run the container:
```
cd $CCPROOT/examples/docker/primary-replica
./run.sh
```
Connect from your local host as follows:
```
psql -h localhost -p 12007 -U testuser -W userdb
psql -h localhost -p 12008 -U testuser -W userdb
```

#### Docker-Compose

Running the example:
```
cd $CCPROOT/examples/compose/primary-replica
docker-compose up
```
To deploy more than one replica, run the following:
```
docker-compose up --scale db-replica=3
```
To psql into the created database containers, first identify the ports exposed on the containers:
```
docker ps
```
Next, using psql, connect to the service:
```
psql -d userdb -h 0.0.0.0 -p <CONTAINER_PORT> -U testuser
```
> **NOTE:**
> See **PG_PASSWORD** in **docker-compose.yml** for the user password.

To tear down the example, run the following:
```
docker-compose stop
docker-compose rm
```

#### Kubernetes

Run the following command to deploy a primary and replica database cluster:
```
cd $CCPROOT/examples/kube/primary-replica
./run.sh
```
It takes about a minute for the replica to begin replicating with the primary. To test out replication, see if replication is underway with this command:
```
psql -h pr-primary -U postgres postgres -c 'table pg_stat_replication'
```
If you see a line returned from that query it means the primary is replicating to the replica. Try creating some data on the primary:
```
psql -h pr-primary -U postgres postgres -c 'create table foo (id int)'
psql -h pr-primary -U postgres postgres -c 'insert into foo values (1)'
```
Then verify that the data is replicated to the replica:
```
psql -h pr-replica -U postgres postgres -c 'table foo'
```
**primary-replica-dc**

If you wanted to experiment with scaling up the number of replicas, you can run the following example:
```
cd $CCPROOT/examples/kube/primary-replica-dc
./run.sh
```
You can verify that replication is working using the same commands as above.

This example creates 2 replicas when it initially starts. To scale up the number of replicas and view what the deployment looks like before and after, run these commands:
```
kubectl get deployment
kubectl scale --current-replicas=2 --replicas=3 deployment/replica-dc
kubectl get deployment
kubectl get pod
```
You can verify that you now have 3 replicas by running this query on the primary:
```
psql -h primary-dc -U postgres postgres -c 'table pg_stat_replication'
```

#### Helm

This example resides under the $CCPROOT/examples/helm directory. View the README to run this example using Helm [here](https://github.com/CrunchyData/crunchy-containers/blob/master/examples/helm/primary-replica/README.md).

#### OpenShift

Run the following command to deploy a primary and replica database cluster:
```
cd $CCPROOT/examples/openshift/primary-replica
./run.sh
```
You can then connect to the database instance as follows:
```
psql -h pr-primary -U testuser -W userdb
```
**primary-replica-dc**

The primary-replica example creates a primary and non-scaling replica; if you wanted to experiment with scaling replicas, try the primary-replica-dc example:
```
cd $CCPROOT/examples/openshift/primary-replica-dc
./run.sh
```
Connect to the PostgreSQL instances with the following:
```
psql -h primary-dc.pgproject.svc.cluster.local -U testuser userdb
psql -h replica-dc.pgproject.svc.cluster.local -U testuser userdb
```
Here is an example of increasing or scaling up the PostgreSQL _replica_ pods to 2:
```
oc scale rc replica-dc-1 --replicas=2
```
Enter the following commands to verify the PostgreSQL replication is working:
```
psql -c 'table pg_stat_replication' -h primary-dc.pgproject.svc.cluster.local -U primary postgres
psql -h replica-dc.pgproject.svc.cluster.local -U primary postgres
```
The replica service is load balancing between multiple replicas; this can be shown by running this command multiple times and the IP address should alternate between the replicas:
```
psql -h replica-dc -U postgres postgres -c 'select inet_server_addr()'
```
**primary-replica-rc-pvc**

The previous primary-replica deployments used emptyDir volumes for persistence. This example uses a PVC based volume in your NFS directory for the primary and the replicas.
```
cd $CCPROOT/examples/openshift/primary-replica-rc-pvc
./run.sh
```
Upon examining the configured NFS directory, the PostgreSQL data directories that are created and used by the primary and replica pods are visible. Testing the example uses the same commands as above, substituting the name **primary-replica-rc-pvc**.

### Primary / Replica Deployment

Starting in release 1.2.8, the PostgreSQL container can accept an environment variable named PGDATA_PATH_OVERRIDE. If set, the /pgdata/subdir path will use a path subdir name of your choosing instead of the default which is the hostname of the container.

This example shows how a Deployment of a PostgreSQL primary is supported. A pod is a deployment that uses a hostname generated by Kubernetes; because of this, a new hostname will be defined upon restart of the primary pod.

For finding the /pgdata that pertains to the pod, you will need to specify a /pgdata/subdir name that never changes. This requirement is handled by the PGDATA_PATH_OVERRIDE environment variable.

The container creates a default database called **userdb**, a default user called **testuser** and a default password of **password**.

This example will create the following in your Kubernetes and OpenShift environments:

- primary-dc service, uses a PVC to persist PostgreSQL data 

- replica-dc service, uses emptyDir persistence 

- primary-dc Deployment of replica count 1 for the primary PostgreSQL database pod 

- replica-dc Deployment of replica count 1 for the replica 

- replica2-dc Deployment of replica count 1 for the 2nd replica 

- ConfigMap to hold a custom postgresql.conf, setup.sql, and pg_hba.conf files 

- Secrets for the primary user, superuser, and normal user to hold the passwords 

- Volume mount for /pgbackrest and /pgwal 

The persisted data for the PostgreSQL primary is found under /pgdata/primary-dc. If you delete the primary pod, the Deployment will create another pod for the primary, and will be able to start up immediately since we are using the same /pgdata/primary-dc data directory.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Kubernetes

Start the example as follows:
```
cd $CCPROOT/examples/kube/primary-deployment
./run.sh
```

#### OpenShift

Start the example as follows:
```
cd $CCPROOT/examples/openshift/primary-deployment
./run.sh
```

### Automated Failover

This example shows how to run the crunchy-watch container to perform an automated failover. For the example to work, the host on which you are running needs to allow read-write access to /run/docker.sock. The crunchy-watch container runs as the **postgres** user, so adjust the file permissions of /run/docker.sock accordingly.

The **primary-replica** example is required to be run before this example.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Run the example as follows:
```
cd $CCPROOT/examples/docker/watch
./run.sh
```
This will start the watch container which tests every few seconds whether the primary database is running, if not, it will trigger a failover (using docker exec) on the replica host.

Test it out by stopping the primary:
```
docker stop primary
docker logs watch
```
Look at the watch container logs to see it perform the failover.

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/watch
./run.sh
```
Check out the log of the watch container as follows:
```
kubectl log watch
```
Then trigger a failover using this command:
```
kubectl delete pod pr-primary
```
Resume watching the watch container's log and verify that it detects the primary is not reachable and performs a failover on the replica.

A final test is to see if the old replica is now a fully functioning primary by inserting some test data into it as follows:
```
psql -h pr-primary -U postgres postgres -c 'create table failtest (id int)'
```
The above command still works because the watch container has changed the labels of the replica to make it a primary, so the primary service will still work and route now to the new primary even though the pod is named replica.

**Tip**

You can view the labels on a pod with this command:
```
kubectl describe pod pr-replica | grep Label
```

#### OpenShift

The following script will create an OpenShift service account which is used by the crunchy-watch container to perform the failover. Also, it will set policies that allow the service account the ability to edit resources within your namespace. Finally, it will create the container that will _watch_ the PostgreSQL cluster.
```
cd $CCPROOT/examples/openshift/watch
./run.sh
```
At this point, the watcher will sleep every 20 seconds (configurable) to see if the primary is responding. If the primary doesn't respond, the watcher will perform the following logic:

- log into OpenShift using the service account 

- set its current project 

- find the first replica pod 

- delete the primary service saving off the primary service definition 

- create the trigger file on the first replica pod 

- wait 20 seconds for the failover to complete on the replica pod 

- edit the replica pod's label to match that of the primary 

- recreate the primary service using the stored service definition 

- loop through the other remaining replica and delete its pod 

At this point, clients when access the primary's service will actually be accessing the new primary. Also, OpenShift will recreate the number of replicas to its original configuration which each replica pointed to the new primary. Replication from the primary to the new replicas will be started as each new replica is started by OpenShift.

To test it out, delete the primary pod and view the watch pod log:
```
oc delete pod pr-primary
oc logs watch
oc get pod
```

### Performing a Backup & Restore

The script assumes you are going to backup the **basic** container created in the first example, so you need to ensure that container is running. This example assumes you have configured NFS as described in the [installation documentation](install.adoc). Things to point out with this example include its use of persistent volumes and volume claims to store the backup data files to an NFS server.

A successful backup will perform pg_basebackup on the **basic** container and store the backup in the NFS mounted volume under a directory named basic-backups. Each backup will be stored in a subdirectory with a timestamp as the name, allowing any number of backups to be kept.

The backup script will do the following:

- Start up a backup container named backup-job 

- Run pg_basebackup on the container named basic 

- Store the backup in /tmp/backups/basic-backups directory 

- Exit after the backup 

When you are ready to restore from the backup, the restore example runs a PostgreSQL container passing in the backup location. The startup of the container will use rsync to copy the backup data to this new container, and then launch PostgreSQL which will use the backup data to start.

The restore script will do the following:

- Start up a container named primary-restore 

- Copy the backup files from the previous backup example into /pgdata 

- Start up the container using the backup files 

- Map the PostgreSQL port of 5432 in the container to your local host port of 12001 

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Run the backup with this command:
```
cd $CCPROOT/examples/docker/backup
./run.sh
```
**primary-restore**

When you are ready to restore from the backup created, run the following example:
```
cd $CCPROOT/examples/docker/restore
./run.sh
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/backup-job
./run.sh
```
The Kubernetes Job type executes a pod and then the pod exits. You can view the Job status using this command:
```
kubectl get job
```
You should find the backup archive in this location:
```
ls /mnt/nfsfileshare/basic-backups
```
**primary-restore**

When ready to restore, you will need the timestamped directory path under /mnt/nfsfileshare/basic-backups in order to locate the backup to use. Edit the primary-restore.json file and update the BACKUP_PATH setting to specify the NFS backup path you want to restore with.
```
"name": "BACKUP_PATH",
"value": "basic-backups/2016-05-27-14-35-33"
```
Running the example:
```
cd $CCPROOT/examples/kube/primary-restore
./run.sh
```
Test the restored database as follows:
```
psql -h primary-restore -U postgres postgres
```

#### OpenShift

Start the backup:
```
cd $CCPROOT/examples/openshift/backup-job
./run.sh
```
The **backup-job.json** file within that directory specifies a **persistentVolumeReclaimPolicy** of **Retain** to tell OpenShift that we want to keep the volume contents after the removal of the PV.

**primary-restore**

When ready to restore, you will need the timestamped directory path under /mnt/nfsfileshare/basic-backups in order to locate the backup to use. Edit the primary-restore.json file and update the BACKUP_PATH setting to specify the NFS backup path you want to restore with.
```
"name": "BACKUP_PATH",
"value": "basic-backups/2016-05-27-14-35-33"
```
Then create the pod:
```
cd $CCPROOT/examples/openshift/primary-restore
./run.sh
```
When the database pod starts, it will copy the backup files to the database directory inside the pod and start up Postgres as usual.

The restore only takes place if:

- the /pgdata directory is empty 

- the /backups directory contains a valid postgresql.conf file

### pgbackrest

Starting in release 1.3.1, the **pgbackrest** utility has been added to the crunchy-postgres container. See the [pgbackrest Documentation](backrest.adoc) for details on how this feature works within the Crunchy Container Suite.

### pgadmin4-http

This example deploys the pgadmin4 v2 web user interface for PostgreSQL without TLS.

After running the example, you should be able to browse to [http://127.0.0.1:5050](http://127.0.0.1:5050) and log into the web application using a user ID of **admin@admin.com** and password of **password**.

If you are running this example using Kubernetes or OpenShift, replace **127.0.0.1:5050** with the <NODE_IP>:30000.

To get the node IP, run the following:
```
# Kube
kubectl describe pod pgadmin4 | grep Node:

# OCP
oc describe pod pgadmin4 | grep Node:
```
See the [pgadmin4 documentation](http://pgadmin.org) for more details.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To run this example, run the following:
```
cd $CCPROOT/examples/docker/pgadmin4-http
./run.sh
```

#### Kubernetes

Start the container as follows:
```
cd $CCPROOT/examples/kube/pgadmin4-http
./run.sh
```

#### OpenShift

To run this example, run the following:
```
cd $CCPROOT/examples/openshift/pgadmin4-http
./run.sh
```

### pgadmin4-https

This example deploys the pgadmin4 v2 web user interface for PostgreSQL with TLS.

After running the example, you should be able to browse to [https://127.0.0.1:5050](https://127.0.0.1:5050) and log into the web application using a user ID of **admin@admin.com** and password of **password**.

If you are running this example using Kubernetes or OpenShift, replace **127.0.0.1:5050** with the <NODE_IP>:30000.

To get the node IP, run the following:
```
# Kube
kubectl describe pod pgadmin4 | grep Node:

# OCP
oc describe pod pgadmin4 | grep Node:
```
See the [pgadmin4 documentation](http://pgadmin.org) for more details.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To run this example, run the following:
```
cd $CCPROOT/examples/docker/pgadmin4-https
./run.sh
```

#### Kubernetes

Start the container as follows:
```
cd $CCPROOT/examples/kube/pgadmin4-https
./run.sh
```

#### OpenShift

To run this example, run the following:
```
cd $CCPROOT/examples/openshift/pgadmin4-https
./run.sh
```

### pgpool

An example is provided that will run a pgpool container in conjunction with the primary and replica example (**primary-replica**) provided above.

You can execute both INSERT and SELECT statements after connecting to pgpool. The container will direct INSERT statements to the primary and SELECT statements will be sent round-robin to both primary and replica.

The container creates a default database called **userdb**, a default user called **testuser** and a default password of **password**.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Create the container as follows:
```
cd $CCPROOT/examples/docker/pgpool
./run.sh
```
Enter the following command to connect to the pgpool container that is mapped to your local port 12003:
```
psql -h localhost -U testuser -p 12003 userdb
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/primary-replica
./run.sh
cd $CCPROOT/examples/kube/pgpool
./run.sh
```
The example is configured to allow the **testuser** to connect to the **userdb** database as follows:
```
psql -h pgpool -U testuser userdb
```
You can view the nodes that pgpool is configured for by running:
```
psql -h pgpool -U testuser userdb -c 'show pool_nodes'
```

#### OpenShift

Run the following command to deploy the pgpool service:
```
cd $CCPROOT/examples/openshift/pgpool
./run.sh
```
Next, you can access the primary replica cluster via the pgpool service by entering the following command:
```
psql -h pgpool -U testuser userdb
psql -h pgpool -U testuser postgres
```
You can view the nodes that pgpool is configured for by running:
```
psql -h pgpool -U testuser userdb -c 'show pool_nodes'
```

### pgbadger

A pgbadger example is provided that will run a HTTP server that when invoked, will generate a pgbadger report on a given database.

pgbadger reads the log files from a database to product an HTML report that shows various PostgreSQL statistics and graphs.

The port utilized for this tool is port 14000 for Docker environments and port 10000 for Kubernetes and Openshift environments.

Additional requirements to build this container include **golang**. On RHEL 7.2, golang is found in the _server optional_ repository which needs to be enabled in order to install this dependency.

The container creates a default database called **userdb**, a default user called **testuser** and a default password of **password**.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To run the example: * modify the run-badger.sh script to refer to the Docker container that you want to run pgbadger against * refer to the container's data directory * start the container that you are referencing

Then, run the example as follows:
```
cd $CCPROOT/examples/docker/badger
./run.sh
```
After execution, the container will run and provide a simple HTTP command you can browse to view the report. As you run queries against the database, you can invoke this URL to generate updated reports:
```
curl http://127.0.0.1:14000/api/badgergenerate
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/badger
./run.sh
```
After execution, the container will run and provide a simple HTTP command you can browse to view the report. As you run queries against the database, you can invoke this URL to generate updated reports:
```
curl http://badger:10000/api/badgergenerate
```
**Tip**

You can view the database container logs using this command:
```
kubectl logs badger-example -c badger
```

#### OpenShift

To run the example:
```
cd $CCPROOT/examples/openshift/badger
./run.sh
```
After execution, the container will run and provide a simple HTTP command you can browse to view the report. As you run queries against the database, you can invoke this URL to generate updated reports:
```
curl http://badger-example:10000/api/badgergenerate
```
You can view this output in a browser if you allow port forwarding from your container to your server host using a command like this:
```
socat tcp-listen:10001,reuseaddr,fork tcp:pg-primary:10000
```
This command maps port 10000 of the service/container to port 10001 of the local server. You can now use your browser to see the badger report.

This is a short-cut to expose a service to the external world. OpenShift would normally configure a router in such a manner where you could _expose_ the service in an OpenShift way.

The official documentation for installing OpenShift on a router can be found [here](https://docs.openshift.com/container-platform/3.6/install_config/router/index.html).

### postgres-gis

An example is provided that will run a postgres-gis pod/service in Kubernetes/OpenShift and a container in Docker.

The container creates a default database called **userdb**, a default user called **testuser** and a default password of **password**.

You can view the extensions that postgres-gis has enabled by running the following command (postgis should be listed):
```
psql -h postgres-gis -U testuser userdb -c '\dx'
```
To validate that PostGIS is installed and which version is running, run the command:
```
psql -h postgres-gis -U testuser userdb -c "SELECT postgis_full_version();"
```
You should expect to see output similar to:
```
postgis_full_version
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 POSTGIS="2.4.2 r16113" PGSQL="100" GEOS="3.5.0-CAPI-1.9.0 r4084" PROJ="Rel. 4.8.0, 6 March 2012" GDAL="GDAL 1.11.4, released 2016/01/25" LIBXML="2.9.1" LIBJSON="0.11" TOPOLOGY RASTER
(1 row)
```
To exercise some of the basic PostGIS functionality for validation (in this case defining 2D geometry point - given inputs of longitude and latitude), run the command:
```
psql -h postgres-gis -U testuser userdb -c "select ST_MakePoint(28.385200,-81.563900);"
```
You should expect to see output similar to:
```
st_makepoint
--------------------------------------------
 0101000000516B9A779C623C40B98D06F0166454C0
(1 row)
```
To shutdown the instance and remove the pod/container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Create the container as follows:
```
cd $CCPROOT/examples/docker/postgres-gis
./run.sh
```
Enter the following command to connect to the postgres-gis container that is mapped to your local port 12000:
```
psql -h localhost -U testuser -p 12000 userdb
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/postgres-gis
./run.sh
```
The example is configured to allow the **testuser** to connect to the **userdb** database as follows:
```
psql -h postgres-gis -U testuser userdb
```

#### OpenShift

Run the following command to deploy the postgres-gis pod and service:
```
cd $CCPROOT/examples/openshift/postgres-gis
./run.sh
```
Next, you can access the postgres-gis pod via the postgres-gis service by entering the following command:
```
psql -h postgres-gis -U testuser userdb
psql -h postgres-gis -U testuser postgres
```

### Metrics Collection

You can collect various PostgreSQL metrics from your database container by running a crunchy-collect container that points to your database container.

This will start up 3 containers and services:

- Prometheus ([http://crunchy-prometheus:9090](http://crunchy-prometheus:9090)) 

- Prometheus gateway ([http://crunchy-promgateway:9091](http://crunchy-promgateway:9091)) 

- Grafana ([http://crunchy-grafana:3000](http://crunchy-grafana:3000)) 

Every 3 minutes the collection container will collect PostgreSQL metrics and push them to the crunchy-prometheus database. You can graph them using the crunchy-grafana container.

If firewalld is enabled in your environment, it may be necessary to allow the necessary ports through the firewall. This can be accomplished by the following:
```
firewall-cmd --permanent --new-zone metrics
firewall-cmd --permanent --zone metrics --add-port 9090/tcp
firewall-cmd --permanent --zone metrics --add-port 9091/tcp
firewall-cmd --permanent --zone metrics --add-port 3000/tcp
firewall-cmd --reload
```
All metrics collected by this set of containers in addition to details on accessing the custom Grafana dashboards provided are fully described in this [document.](metrics.adoc)

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To start this set of containers, run the following:
```
cd $CCPROOT/examples/docker/metrics
./run.sh
```
An example has been provided that runs a database container in addition to the associated metrics collection container. Run the example as follows:
```
cd $CCPROOT/examples/docker/collect
./run.sh
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/metrics
./run.sh
```
If you want your metrics and dashboards to persist to NFS, run this script:
```
cd $CCPROOT/examples/kube/metrics
./run-pvc.sh
```
This example runs a pod that includes a database container and a metrics collection container. A service is also created for the pod.
```
cd $CCPROOT/examples/kube/collect
./run.sh
```
You can view the collect container logs using this command:
```
kubectl logs -c collect primary-collect
```
You can access the database or drive load against it using this command:
```
psql -h primary-collect -U postgres postgres
```

#### OpenShift

First, create the crunchy-metrics pod which contains the Prometheus data store and the Grafana graphing web application:
```
cd $CCPROOT/examples/openshift/metrics
./run.sh
```
Next, start a PostgreSQL pod that has the crunchy-collect container as follows:
```
cd $CCPROOT/examples/openshift/collect
./run.sh
```

### Vacuum

You can perform a PostgreSQL vacuum command by running the crunchy-vacuum container. You specify a database to vacuum using environment variables. By default, it will specify the **basic** example; you will need to start the **basic** container before running **vacuum**.

The crunchy-vacuum container image exists to allow a DBA a way to run a job either individually or scheduled to perform a variety of vacuum operations.

This example performs a vacuum on a single table in the primary PostgreSQL database. The crunchy-vacuum image is executed, passed in the PostgreSQL connection parameters to the single-primary PostgreSQL container. The type of vacuum performed is dictated by the environment variables passed into the job. Vacuum is controlled via the following environment variables:

- VAC_FULL - when set to true adds the FULL parameter to the VACUUM command 

- VAC_TABLE - when set, allows you to specify a single table to vacuum, when not specified, the entire database tables are vacuumed 

- JOB_HOST - required variable is the PostgreSQL host we connect to 

- PG_USER - required variable is the PostgreSQL user we connect with 

- PG_DATABASE - required variable is the PostgreSQL database we connect to 

- PG_PASSWORD - required variable is the PostgreSQL user password we connect with 

- PG_PORT - allows you to override the default value of 5432 

- VAC_ANALYZE - when set to true adds the ANALYZE parameter to the VACUUM command 

- VAC_VERBOSE - when set to true adds the VERBOSE parameter to the VACUUM command 

- VAC_FREEZE - when set to true adds the FREEZE parameter to the VACUUM command 

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Run the example as follows:
```
cd $CCPROOT/examples/docker/vacuum
./run.sh
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/vacuum-job/
./run.sh
```
Verify the job is completed:
```
kubectl get job
```
View the docker log of the vacuum job's pod:
```
docker logs $(docker ps -a | grep crunchy-vacuum | cut -f 1 -d' ')
```

#### OpenShift

Run the example as follows:
```
cd ../vacuum-job
./run.sh
```

### Cron Scheduler

The crunchy-dba container implements a cron scheduler. The purpose of the crunchy-dba container is to offer a way to perform simple DBA tasks that occur on some form of schedule such as backup jobs or running a vacuum on a single PostgreSQL database container (such as the **basic** example).

You can either run the crunchy-dba container as a single pod or include the container within a database pod.

The crunchy-dba container makes use of a Service Account to perform the startup of scheduled jobs. The Kubernetes Job type is used to execute the scheduled jobs with a Restart policy of Never.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Kubernetes

The script to schedule vacuum on a regular schedule is executed through the following commands:
```
cd $CCPROOT/examples/kube/dba
./run-vac.sh
```
To run the script for scheduled backups, run the following in the same directory:
```
./run-backup.sh
```
Individual parameters for both can be modified within their respective JSON files; please see [containers.adoc](https://github.com/CrunchyData/crunchy-containers/blob/master/docs/containers.adoc) for a full list of what can be modified.

### pgbouncer

The pgbouncer utility can be used to provide a connection pool to PostgreSQL databases.

This example configures pgbouncer to provide connection pooling for the primary and pg-replica databases. It also sets the FAILOVER environment variable which will cause a failover to be triggered if the primary database can not be reached.

After triggering the failover, pgbouncer will notice that the primary is not reachable and will touch the trigger file on the configured replica database to start the failover. The pgbouncer container will then reconfigure pgbouncer to relabel the replica database into the primary database so clients to pgbouncer will be able to connect to the primary as before the failover.

This example is required to run in conjunction with another container, by default the **primary-replica** example.

Additionally, the example assumes you have an NFS share path of /mnt/nfsfileshare/. NFS is required to mount the pgbouncer configuration files which are then mounted to /pgconf in the crunchy-pgbouncer container.

If you mount a /pgconf volume, crunchy-postgres will look at that directory for postgresql.conf, pg_hba.conf, and setup.sql. If it finds one of them it will use that file instead of the default files.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

The pgbouncer example is run as follows:
```
cd $CCPROOT/examples/docker/pgbouncer
./run.sh
```
To trigger the failover, stop the primary database:
```
docker stop primary
```
To log into the database from the pgbouncer connection pool you would enter the following using the default password **password**:
```
psql -h localhost -p 12005 -U testuser primary
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/pgbouncer
./run.sh
```
Connect to the **primary** and **replica** databases as follows:
```
psql -h pgbouncer -U postgres primary
psql -h pgbouncer -U postgres replica
```
The names **primary** and **replica** are pgbouncer configured names and don't necessarily have to match the database name in the actual PostgreSQL instance.

View the pgbouncer log as follows:
```
kubectl log pgbouncer
```
Next, test the failover capability within the crunchy-watch container using the following:
```
kubectl delete pod pr-primary
```
Take another look at the pgbouncer log and you will see it trigger the failover to the replica pod. After this failover you should be able to execute the command:
```
psql -h pgbouncer -U postgres primary
```

#### OpenShift

Run the example as follows:
```
cd $CCPROOT/examples/openshift/pgbouncer
./run.sh
```
Test the example by killing off the primary database container as follows:
```
oc delete pod pr-primary
```
Then watch the pgbouncer log as follows to confirm it detects the loss of the primary:
```
oc logs pgbouncer
```
After the failover is completed, you should be able to access the new primary using the primary service as follows:
```
psql -h pr-primary.openshift.svc.cluster.local -U primaryuser postgres
```
and access the replica as follows:
```
psql -h pr-replica.openshift.svc.cluster.local -U primaryuser postgres
```
or via the pgbouncer proxy as follows:
```
psql -h pgbouncer.openshift.svc.cluster.local  -U primaryuser primary
```

### Synchronous Replication

This example deploys a PostgreSQL cluster with a primary, a synchronous replica, and an asynchronous replica. The two replicas share the same Service.

Connect to the **primarysync** and **replicasync** databases as follows for both the Kubernetes and OpenShift environments:
```
psql -h primarysync -U postgres postgres -c 'create table test (id int)'
psql -h primarysync -U postgres postgres -c 'insert into test values (1)'
psql -h primarysync -U postgres postgres -c 'table pg_stat_replication'
psql -h replicasync -U postgres postgres -c 'select inet_server_addr(), * from test'
psql -h replicasync -U postgres postgres -c 'select inet_server_addr(), * from test'
psql -h replicasync -U postgres postgres -c 'select inet_server_addr(), * from test'
```
This set of queries will show you the IP address of the PostgreSQL replica container. Notice the changing IP address due to the round-robin service proxy being used for both replicas. The example queries also show that both replicas are replicating from the primary.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

To run this example, run the following:
```
cd $CCPROOT/examples/docker/sync
./run.sh
```
You can test the replication status on the primary by using the following command and the password "password":
```
psql -h 127.0.0.1 -p 12010 -U postgres postgres -c 'table pg_stat_replication'
```
You should see 2 rows, 1 for the async replica and 1 for the sync replica. The sync_state column shows values of async or sync.

You can test replication to the replicas by entering some data on the primary like this, and then querying the replicas for that data:
```
psql -h 127.0.0.1 -p 12010 -U postgres postgres -c 'create table foo (id int)'
psql -h 127.0.0.1 -p 12010 -U postgres postgres -c 'insert into foo values (1)'
psql -h 127.0.0.1 -p 12011 -U postgres postgres -c 'table foo'
psql -h 127.0.0.1 -p 12012 -U postgres postgres -c 'table foo'
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/sync
./run.sh
```

#### OpenShift

Running the example:
```
cd $CCPROOT/examples/openshift/sync
./run.sh
```

### Statefulsets

This example deploys a statefulset named **pgset**. The statefulset is a new feature in Kubernetes as of version 1.5 and in OpenShift Origin as of version 3.5. Statefulsets have replaced PetSets going forward.

This example creates 2 PostgreSQL containers to form the set. At startup, each container will examine its hostname to determine if it is the first container within the set of containers.

The first container is determined by the hostname suffix assigned by Kubernetes to the pod. This is an ordinal value starting with **0**.

If a container sees that it has an ordinal value of **0**, it will update the container labels to add a new label of:
```
name=$PG_PRIMARY_HOST
```
In this example, PG_PRIMARY_HOST is specified as **pgset-primary**.

By default, the containers specify a value of **name=pgset-replica**.

There are 2 services that end user applications will use to access the PostgreSQL cluster, one service (pgset-primary) routes to the primary container and the other (pgset-replica) to the replica containers.
```
$ kubectl get service
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes      10.96.0.1       <none>        443/TCP    22h
pgset           None            <none>        5432/TCP   1h
pgset-primary    10.97.168.138   <none>        5432/TCP   1h
pgset-replica   10.97.218.221   <none>        5432/TCP   1h
```
To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Kubernetes

Start the example as follows:
```
cd $CCPROOT/examples/kube/statefulset
./run.sh
```
You can access the primary database as follows:
```
psql -h pgset-primary -U postgres postgres
```
You can access the replica databases as follows:
```
psql -h pgset-replica -U postgres postgres
```
You can scale the number of containers using this command, this will essentially create an additional replica databse:
```
kubectl scale pgset --replica=3
```

##### Statefulset using Dynamic Provisioning

The example in **examples/statefulset-dyn** is almost an exact copy of the previous statefulset example; however, this example uses Dynamic Storage Provisioning to automatically create Persistent Volume Claims based on StorageClasses. This Kubernetes feature is available on Google Container Engine which this example was tested upon.

You can run the example as follows:
```
cd $CCPROOT/examples/kube/statefulset-dyn
./run.sh
```
This will create a StorageClass named **slow** which you can view using:
```
kubectl get storageclass
NAME      TYPE
slow      kubernetes.io/gce-pd
```
The example causes Kube to create the required PVCs automatically:
```
kubectl get pvc
NAME             STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS   AGE
pgdata-pgset-0   Bound     pvc-06334f6f-371b-11e7-9bda-42010a8000e9   1Gi        RWX           slow           5m
pgdata-pgset-1   Bound     pvc-063795b3-371b-11e7-9bda-42010a8000e9   1Gi        RWX           slow           5m
```
More information on dynamic storage provisioning can be found here: [https://kubernetes.io/docs/concepts/storage/persistent-volumes/](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

#### Helm

This example resides under the $CCPROOT/examples/helm directory. View the README to run this example using Helm [here](https://github.com/CrunchyData/crunchy-containers/blob/master/examples/helm/statefulset/README.md).

#### OpenShift

Build the example:
```
cd $CCPROOT/examples/openshift/statefulset
./run.sh
```
This will create a statefulset named pgset, which will create 2 pods, pgset-0 and pgset-1:
```
oc get statefulset
oc get pod
```
A service is created for the primary and another service for the replica:
```
oc get service
```
The statefulset ordinal value of 0 is used to determine which pod will act as the PostgreSQL primary, all other ordinal values will assume the replica role.

### pitr - PITR (point in time recovery)

This is an example of performing point in time recovery on your database. See the [PITR Documentation](pitr.adoc) for details on PITR concepts and how PITR is implemented within the Suite.

It takes about 1 minute for the database to become ready for use after initially starting.

This database is created with the ARCHIVE_MODE and ARCHIVE_TIMEOUT environment variables set.
> **WARNING:**
> WAL segment files are written to the /tmp directory. Leaving the example running for a long time could fill up your /tmp directory.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Create a database container as follows:
```
cd $CCPROOT/examples/docker/pitr
./run-primary-pitr.sh
```
Next, we will create a base backup of that database using this:
```
./run-primary-pitr-backup.sh
```
After creating the base backup of the database, WAL segment files are created every 60 seconds that contain any database changes. These segments are stored in the /tmp/primary-data/master-wal directory.

Create some data in your database using this command:
```
psql -h 127.0.0.1 -p 12000 -U postgres postgres -c "select pg_create_restore_point('beforechanges')"
psql -h 127.0.0.1 -p 12000 -U postgres postgres -c 'create table pitrtest (id int)'
psql -h 127.0.0.1 -p 12000 -U postgres postgres -c "select pg_create_restore_point('afterchanges')"
psql -h 127.0.0.1 -p 12000 -U postgres postgres -c "select pg_create_restore_point('nomorechanges')"
psql -h 127.0.0.1 -p 12000 -U postgres postgres -c "checkpoint"
```
Next, stop the database to avoid conflicts with the WAL files while attempting to do a restore from them:
```
docker stop primary-pitr
```
The commands above set restore point labels which we can use to mark the points in the recovery process we want to reference when creating our restored database. Points before and after the test table were made.

Next, let's edit the restore script to use the base backup files created in the step above. You can view the backup path name under the /tmp/backups/primary-pitr-backups/ directory. You will see another directory inside of this path with a name similar to **2016-09-21-21-03-29**. Copy and paste that value into the run-restore-pitr.sh script in the **BACKUP** environment variable.

In order to restore the database before we created test table in the last command, you'll need uncomment to the RECOVERY_TARGET_NAME label **-e RECOVERY_TARGET_NAME=beforechanges** to define the restore target name. After that, run the script.
```
vi ./run-restore-pitr.sh
./run-restore-pitr.sh
```
The WAL segments are read and applied when restoring from the database backup. At this point, you should be able to verify that the database was restored to the point before creating the test table:
```
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'table pitrtest'
```
This SQL command should show that the pitrtest table does not exist at this recovery time. The output should be similar to:

PostgreSQL allows you to pause the recovery process if the target name or time is specified. This pause would allow a DBA a chance to review the recovery time/name and see if this is what they want or expect. If so, the DBA can run the following command to resume and complete the recovery:
```
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'select pg_xlog_replay_resume()'
```
Until you run the statement above, the database will be left in read-only mode.

Next, run the script to restore the database to the **afterchanges** restore point, do this by updating the RECOVERY_TARGET_NAME to **afterchanges**:
```
vi ./run-restore-pitr.sh
./run-restore-pitr.sh
```
After this restore, you should be able to see the test table:
```
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'table pitrtest'
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'select pg_xlog_replay_resume()'
```
Lastly, start a recovery using all of the WAL files. This will get the restored database as current as possible. To do so, edit the script to remove the RECOVERY_TARGET_NAME environment setting completely:
```
./run-restore-pitr.sh
sleep 30
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'table pitrtest'
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'create table foo (id int)'
```
At this point, you should be able to create new data in the restored database and the test table should be present. When you recover the entire WAL history, resuming the recovery is not necessary to enable writes.

#### Kubernetes

This example is identical to the OpenShift PITR example; please see below for details on how the PITR example works.

The only differences are the following:

- paths are **$CCPROOT/examples/kube/pitr** 

- JSON and scripts are modified to work with Kubernetes 

- **kubectl** commands are used instead of **oc** commands 

- database services resolve to **default.svc.cluster.local** instead of **openshift.svc.cluster.local**

#### OpenShift

Start by running the example database container:
```
cd $CCPROOT/examples/openshift/pitr
./run-primary-pitr.sh
```
This step will create a database container, **primary-pitr**. This container is configured to continuously write WAL segment files to a mounted volume (/pgwal).

After you start the database, you will create a base backup using this command:
```
./run-primary-pitr-backup.sh
```
This will create a backup and write the backup files to a persistent volume (/pgbackup).

Next, create some recovery targets within the database by running the SQL commands against the **primary-pitr** database as follows:
```
./run-sql.sh
```
This will create recovery targets named **beforechanges**, **afterchanges**, and **nomorechanges**. It will create a table, **pitrtest**, between the **beforechanges** and **afterchanges** targets. It will also run a SQL CHECKPOINT to flush out the changes to WAL segments.

Next, now that we have a base backup and a set of WAL files containing our database changes, we can shut down the **primary-pitr** database to simulate a database failure. Do this by running the following:
```
oc delete pod primary-pitr
```
Next, we will create 3 different restored database containers based upon the base backup and the saved WAL files.

First, we restore prior to the **beforechanges** recovery target. This recovery point is **before** the **pitrtest** table is created.

Edit the primary-pitr-restore.json file, and edit the environment variable to indicate we want to use the **beforechanges** recovery point:
```
}, {
"name": "RECOVERY_TARGET_NAME",
"value": "beforechanges"
}, {
```
Then run the following to create the restored database container:
```
./run-restore-pitr.sh
```
After the database has restored, you should be able to perform a test to see if the recovery worked as expected:
```
psql -h primary-pitr-restore.openshift.svc.cluster.local -U postgres postgres -c 'table pitrtest'
psql -h primary-pitr-restore.openshift.svc.cluster.local -U postgres postgres -c 'create table foo (id int)'
psql -h primary-pitr-restore.openshift.svc.cluster.local -U postgres postgres -c 'select pg_xlog_replay_resume()'
psql -h primary-pitr-restore.openshift.svc.cluster.local -U postgres postgres -c 'create table foo (id int)'
```
The output of these command should show that the **pitrtest** table is not present. It should also show that you can not create a new table because the database is paused in recovery mode. Lastly, if you execute a **resume** command, it will show that you can now create a table as the database has fully recovered.

You can also test that if **afterchanges** is specified, that the **pitrtest** table is present but that the database is still in recovery mode.

Lastly, you can test a full recovery using **all** of the WAL files, if you remove the **RECOVERY_TARGET_NAME** environment variable completely.

The NFS portions of this example depend upon an NFS file system with the following path configurations be present:
```
/mnt/nfsfileshare
/mnt/nfsfileshare/backups
/mnt/nfsfileshare/WAL
```
Once you recover a database using PITR, it will be in read-only mode. To make the database resume as a writable database, run the following sql command:
```
select pg_xlog_replay_resume();
```
This command changed for PG10 to:
```
postgres=# select pg_wal_replay_resume();
```

### pg_audit

This example provides an example of enabling pg_audit output. As of release 1.3, pg_audit is included in the crunchy-postgres container and is added to the PostgreSQL shared library list in the postgresql.conf.

Given the numerous ways pg_audit can be configured, the exact pg_audit configuration is left to the user to define. pg_audit allows you to configure auditing rules either in postgresql.conf or within your SQL script.

For this test, we place pg_audit statements within a SQL script and verify that auditing is enabled and working. If you choose to configure pg_audit via a postgresql.conf file, then you will need to define your own custom postgresql.conf file and mount it to override the default postgresql.conf file.

#### Docker

Run the following to create a database container:
```
cd $CCPROOT/examples/docker/pgaudit
./run.sh
```
This starts an instance of the Audit container (running crunchy-postgres) on port 12005 on localhost. You can then run the test script as follows:
```
./test-pgaudit.sh
```
This test executes a SQL file which contains pg_audit configuration statements as well as executes some basic SQL commands. These SQL commands will cause pg_audit to create audit log messages in the pg_log log file created by the database container.

#### Kubernetes

Run the following:
```
cd $CCPROOT/examples/kube/pgaudit
./run.sh
```
The script will create an Audit pod (running the crunchy-postgres container) on the Kubernetes instance and then executes a SQL file which contains pg_audit configuration statements as well as executes some basic SQL commands. These SQL commands will cause pg_audit to create audit log messages in the pg_log log file created by the database container.

#### OpenShift

Run the following:
```
cd $CCPROOT/examples/openshift/pgaudit
./run.sh
```
The script will create an Audit pod (running the crunchy-postgres container) on the OpenShift instance and then executes a SQL file which contains pg_audit configuration statements as well as executes some basic SQL commands. These SQL commands will cause pg_audit to create audit log messages in the pg_log log file created by the database container.

### Docker Swarm

This example shows how to run a primary and replica database container on a Docker Swarm (v.1.12) cluster.

First, set up a cluster. The Kubernetes libvirt coreos cluster example works well; see [coreos-libvirt-cluster.](http://kubernetes.io/docs/getting-started-guides/libvirt-coreos/)

Next, on each node, create the Swarm using these [Swarm Install instructions.](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/)

Includes the command on the manager node:
```
docker swarm init --advertise-addr 192.168.10.1
```
Then the command on all the worker nodes:
```
docker swarm join \
     --token SWMTKN-1-65cn5wa1qv76l8l45uvlsbprogyhlprjpn27p1qxjwqmncn37o-015egopg4jhtbmlu04faon82u \
         192.168.10.1.37
```
Before creating Swarm services, for service discovery you need to define an overlay network to be used by the services you will create. Create the network like this:
```
docker network create --driver overlay crunchynet
```
We want to have the primary database always placed on a specific node. This is accomplished using node constraints as follows:
```
docker node inspect kubernetes-node-1 | grep ID
docker node update --label-add type=primary 18yrb7m650umx738rtevojpqy
```
In the above example, the kubernetes-node-1 node with ID 18yrb7m650umx738rtevojpqy has a user defined label of **primary** added to it. The primary service specifies **primary** as a constraint when created; this tells Swarm to place the service on that specific node. The replica specifies a constraint of **node.labels.type != primary** to have the replica always placed on a node that is not hosting the primary service.

#### Docker

After you set up the Swarm cluster, you can then run this example as follows on the **Swarm Manager Node**:
```
cd $CCPROOT/examples/docker/swarm-service
./run.sh
```
You can then find the nodes that are running the primary and replica containers by:
```
docker service ps primary
docker service ps replica
```
You can also scale up the number of **replica** containers.
```
docker service scale replica=2
docker service ls
```
Verify you have two replicas within PostgreSQL by viewing the **pg_stat_replication** table. The password is **password** by default when logged into the kubernetes-node-1 host:
```
docker exec -it $(docker ps -q) psql -U postgres -c 'table pg_stat_replication' postgres
```
You should see a row for each replica along with its replication status.

### pg_upgrade

Starting in release 1.3.1, the upgrade container will let you perform a pg_upgrade on a 9.5 database converting its data to a 9.6 version.

This example assumes you have run **primary-pvc** using a PG 9.5 image such as **centos7-9.5.12-1.8.1** prior to running this upgrade.

Prior to starting this example, shut down the **primary-pvc** database using the **examples/kube/primary-pvc/cleanup.sh** script.

Prior to running this example, make sure your CCP_IMAGE_TAG environment variable is using a PG 9.6 image such as **centos7-9.6.8-1.8.1**.

This will create the following in your Kubernetes environment:

- a Kubernetes Job running the **crunchy-upgrade** container 

- a new data directory name **primary-upgrade** found in the **pgnewdata** PVC

#### Kubernetes

Start the upgrade as follows:
```
cd $CCPROOT/examples/kube/upgrade
./run.sh
```
If successful, the Job will end with a Successful status. Verify the results of the Job by examining the Job's pod log:
```
kubectl get pod -a -l job-name=upgrade-job
kubectl logs -l job-name=upgrade-job
```
You can verify the upgraded database by running the **examples/kube/primary-upgrade** example. This example will mount the newly created and upgraded database files. Database tables and data that were in the **primary-pvc** test database should be found in the **primary-upgrade** database.

### Performing a pg_dump

The script assumes you are going to backup the **basic** container created in the first example, so you need to ensure that container is running. This example assumes you have configured NFS as described in the [installation documentation](install.adoc). Things to point out with this example include its use of persistent volumes and volume claims to store the backup data files to an NFS server.

A successful backup will perform pg_dump/pg_dumpall on the basic and store the resulting files in the NFS mounted volume under a directory named using the database host name plus -dumps as a sub-directory, then followed by a unique backup directory based upon a date/timestamp - allowing any number of backups to be kept.

The dump script will do the following:

- Start up a backup container named pgdump-job 

- Run pg_dump/pg_dumpall on the container named basic 

- Store the backup in the PV in a path named with a date/timestamp 

- Exit after the backup 

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Run the backup with this command:
```
cd $CCPROOT/examples/docker/pgdump
./run.sh

#Output from the run.sh script will include output like:
#starting backup container...
#Cleaning up...
#pgdump
#pgdump
#pgdump-volume
#pgdump-volume
#0367ee9cbe776450973f63ab875ab868c3aa8902ec3e073de8adbab9baa75c14

#Make note of the container ID from above to run the following command
docker logs 0367ee9cbe776450973f63ab875ab868c3aa8902ec3e073de8adbab9baa75c14 2>&1 | grep "output"

#That will return the location where the pg_dump/pg_dumpall file(s) were written.  E.g.:
#PGDUMP_ALL output file has been written to: /pgdata/basic-dumps/2018-02-14-05-00-23/pgdumpall.sql

#Make note of the timestamp above and run a find to get the fully-qualified filesystem path where the file was written.  E.g.:
sudo find / -name 2018-02-14-05-00-23

#That will return the fully-qualified path, where the file can be accessed/copied to your local filesystem.  E.g.:
#/var/lib/docker/volumes/pgdump-volume/_data/basic-dumps/2018-02-14-05-00-23

#Copy the file (path returned above + the filename) to your local filesystem for use or for running with the pg_restore container:
sudo cp -p /var/lib/docker/volumes/pgdump-volume/_data/basic-dumps/2018-02-14-05-00-23/pgdumpall.sql /tmp
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/pgdump-job
./run.sh
```
The Kubernetes Job type executes a pod and then the pod exits. You can view the Job status using this command:
```
kubectl get job
```

#### OpenShift

Start the backup:
```
cd $CCPROOT/examples/openshift/pgdump-job
./run.sh
```
The **pgdump-job.json** file within that directory specifies options that control the behavior of the pgdump-job. E.g. Whether to run pg_dump vs pg_dumpall, whether to include verbose output, if database objects should be cleanly dropped before being recreated, etc.

### Performing a pg_restore

The script assumes you are going to restore to the **basic** container created in the first example, so you need to ensure that container is running. This example assumes you have configured NFS as described in the [installation documentation](install.adoc). Things to point out with this example include its use of persistent volumes and volume claims to store the backup data files to an NFS server.

Successful use of the crunchy-restore container will run a job to restore files generated by pg_dump/pg_dumpall to a container via psql/pg_restore; then container will terminate successfully and signal job completion.

The restore script will do the following:

- Mount a PV/PVC as named in the JSON file 

- Run psql/pg_restore on the container named basic (or as specified otherwise in the JSON file) 

- Exit after the backup 

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

#### Docker

Run the backup with this command:
```
cd $CCPROOT/examples/docker/pgrestore
./run.sh
```

#### Kubernetes

Running the example:
```
cd $CCPROOT/examples/kube/pgrestore-job
./run.sh
```
The Kubernetes Job type executes a pod and then the pod exits. You can view the Job status using this command:
```
kubectl get job
```

#### OpenShift

Start the restore:
```
cd $CCPROOT/examples/openshift/pgrestore-job
./run.sh
```
The **pgrestore-job.json** file within that directory specifies options that control the behavior of the pgrestore-job. E.g. Whether to restore via psql vs pg_restore (dependent on the PGRESTORE_FORMAT variable), whether to include verbose output, if database objects should be cleanly dropped before being recreated, etc.

#### SSHD PostgreSQL

To enable SSHD on PostgreSQL, see the [SSHD Documentation](sshd.adoc).

## Legal Notices

Copyright &copy; 2018 Crunchy Data Solutions, Inc.

CRUNCHY DATA SOLUTIONS, INC. PROVIDES THIS GUIDE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF NON INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

Crunchy, Crunchy Data Solutions, Inc. and the Crunchy Hippo Logo are trademarks of Crunchy Data Solutions, Inc.