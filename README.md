# UpCloud Storage Bencher

A set of scripts to benchmark UpCloud storage. Used to debug MaxIOPS performance
bottlenecks. Can be adjuted to benchmark other block storage types, in any number
of regions with any type of OS (default Rocky Linux 8).

The script will spin up a few servers in parallel in pre-defined regions (see `main.sh`), 
attach 3 MaxIOPS storage devices, and run fio benchmarks on all of them. The 
benchmark data is then plotted, and the graph is copied over to the `graphs` 
directory.

You can edit the regions where servers will be created by editing the `REGIONS`
variable in the main.sh script.

### Running

#### Requirements

```
upctl scp jq
```

#### Run

Point the script to the private key of a ssh keypair, the public key will be added
to the remote server.

```
SSH_KEY=~/.ssh/id_upcloud ./main.sh
```

### Graphs

Graphs can be found in the `graphs` directory.

Server with bandwidth issues:

![Bad Storage Example](/graphs/2022-09-21-1663792164/bencher-us-nyc1-vdc.png)

Server without bandwidth issues:

![Good Storage Example](/graphs/2022-09-21-1663792164/bencher-nl-ams1-vdc.png)
