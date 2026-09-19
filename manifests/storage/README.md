```bash
kubectl apply -f manifests/storage/openebs-test-pvc.yaml
```

```bash
kubectl get pvc openebs-test-pvc
```

```bash
kubectl apply -f manifests/storage/openebs-test-pod.yaml

kubectl get pod openebs-test

kubectl exec openebs-test -- ls -lh /data

kubectl exec openebs-test -- cat /data/test.txt

kubectl delete -f manifests/storage/openebs-test-pod.yaml
kubectl delete -f manifests/storage/openebs-test-pvc.yaml

```