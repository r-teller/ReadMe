## Remove Stopped containers
```bash
docker rm $(docker ps -a -f status=exited -q)
```

## Shows only ContainerID, Image, Status and names of running containers
```bash
docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

## Using strace to debug container process

```bash
ps -axfo pid,ppid,uname,cmd | less
## Start the NGINX docker container
docker run -itd --name nginxDebug nginx:latest

## Extract the PID from the container
parentPID=`docker inspect -f '{{.State.Pid}}' datapath000`
### Example output
### docker inspect -f '{{.State.Pid}}' nginxDebug 
### 7645

## Find the NGINX PID that was forked from the parent PID
childPID=`pgrep -P ${parentPID} -f controller-agent`
### Example output
### pgrep -aP 7645 -f nginx
### 7699 nginx: worker process
### 
### pgrep -P 7645 -f nginx
### 7699

## Find all worker PIDs that belong to the NGINX PID
workerPID=`pgrep -d ' ' -P ${childPID}`
### Example output



parentPID=`docker inspect -f '{{.State.Pid}}' datapath000`
controllerAgentPID=`pgrep -P ${parentPID} -f controller-agent`
AVRdPID=`pgrep -P ${controllerAgentPID}`
workerPID=`pgrep -P ${AVRdPID}`
sudo strace -e trace=network,read,write -f $(echo ${workerPID} | sed 's/\([0-9]*\)/\-p \1/g') 
```