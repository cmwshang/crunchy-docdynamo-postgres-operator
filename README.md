# crunchy-docdynamo-postgres-operator-postgres-operator
Documentation generation engine for Crunchy Data postgres-operator. Source code for the output documentation is adoc (asciidoc) files.

## Setting up the Example Environment
This repository contains a Vagrantfile for building a VM that will automatically pull in the most recent docDynamo and postgres-operator code from GitHub.

A virtual machine (such as VirtualBox https://www.vagrantup.com) and Vagrant (https://www.vagrantup.com) are required to run the example.

1. Get the postgres-operator from Crunchy Data Github.
2. cd to the directory on your local machine and run the following:

```
vagrant up
vagrant ssh
```

It will take several minutes to build the VM but once built, the VM can remain running or quickly restarted and used continuously.

## Building the Docs
Inside the Vagrant box, running the build script will generate the XML files required by docDynamo. All XML that are specified in the build script can be rebuilt using:

```
/crunchy-docdynamo-postgres-operator/./build-docdynamo-docs.sh all create
```

To only generate a specific file or one that is not listed yet in the build script, then use the file name instead of "all"

```
/crunchy-docdynamo-postgres-operator/./build-docdynamo-docs.sh containers create
```

Next run docDynamo to build all the HTML, PDF and Markdown files specified in the doc/manifest.xml directory:

```
/docdynamo/bin/docdynamo --doc-path=/crunchy-docdynamo-postgres-operator/doc
```

To generate a specific formate, use the --out option. For example, the following will build a markdown file:

```
/docdynamo/bin/docdynamo --doc-path=/crunchy-docdynamo-postgres-operator/doc --out=markdown
```

All output will be written to the doc/output directory.

## Refreshing from the Crunchy postgres-operator repository
After having built the VM, if newer source documents have been committed to postgres-operator, they can be pulled into the VM by performing the following inside the VM.

```
sudo rm -rf /postgres-operator
sudo git clone https://github.com/CrunchyData/postgres-operator.git /postgres-operator
```

If new adoc files have been added, then edit the manifest.xml file and add the name of the new file to the source-list section and as a render-source to the render sections as appropriate.

Then follow the instructions under the section **Building the Docs** above.
