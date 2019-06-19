## Example to collect log for k8s pod without know the pod name
```bash
kubectl logs -fn bigip-ingress \
  $( \
    kubectl get pods -n bigip-ingress -o json | \
    jq -r '.items|map(select(.status.containerStatuses[].ready == true))|.[].metadata.name' \
    )
```
