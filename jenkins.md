# Adding Trusted CA to Jenkins running in GKE

When you run Jenkins as a container within GKE you will run into issues adding additional Trusted CA certs. When you exec into the pod you will be logged in as jenkins and not have the required permissions to modify the trusted-ca bundle

Find the node that the jenkins pod is running on
```bash
kubectl get pods -o wide
```
ssh into the node and find the jenkins master container
```bash
docker ls | grep -i master
```

exec into docker container
```bash
docker exec -it --user root k8s_jenkins-master_jenkins-dev /bin/bash
```

import the ca certificate
```bash
keytool -no-prompt -import --keystore /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts -alias neustar-ca -file /var/jenkins_home
/trusted_ca.crt -storepass changeit
```