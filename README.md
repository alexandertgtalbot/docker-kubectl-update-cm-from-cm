# docker-kubectl-update-cm-from-cm

![Docker Automated build](https://img.shields.io/docker/automated/alexandertgtalbot/kubectl-update-cm-from-cm)
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/alexandertgtalbot/kubectl-update-cm-from-cm)
![Docker Pulls](https://img.shields.io/docker/pulls/alexandertgtalbot/kubectl-update-cm-from-cm)

A helper image/container to add, update or remove data elements, i.e. key-value pairs, to/from a target Kubernetes (K8s) Config Map (CM). Where data is added or updated it is done referencing a distinct config map who's data elements will then be added to the target CM. This helper image was originally intended for use within the context of a Kudo Operator which deals with updating the reference CM dynamically.

[GitHub](https://github.com/alexandertgtalbot/docker-kubectl-update-cm-from-cm)
[Docker Hub](https://hub.docker.com/repository/docker/alexandertgtalbot/kubectl-update-cm-from-cm)

## Build and Publish the image
```
NAMESPACE=YOUR_NS_OR_PRIVATE_REGISTRY
docker build . --tag $NAMESPACE/kubectl-update-cm-from-cm
docker push $NAMESPACE/kubectl-update-cm-from-cm 
```

## Example usage
Create an empty CM that represents the target CM that will recieve updates from a temporary or reference CM:
```
kubectl create ns master-config-map-namespace
kubectl create cm -n master-config-map-namespace master-config-map
```

Create a reference CM who's data elements will be added to the master CM, see above CM "master-config-map":
```
kubectl create ns reference-config-map-namespace
kubectl create cm -n reference-config-map-namespace reference-config-map --from-literal=aRandomKey=aRandomValue
```

Define a K8s Job to add to or update a master CM from the reference CM:
```
cat << 'EOF' > add-to-or-update-config-map-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: add-to-or-update-config-map-job
spec:
  template:
    metadata:
      name: add-to-or-update-config-map
    spec:
      restartPolicy: Never
      containers:
        - name: add-to-or-update-config-map-job
          image: alexandertgtalbot/kubectl-update-cm-from-cm
          imagePullPolicy: IfNotPresent
          env:
            - name: REFERENCE_CONFIG_MAP_NAME
              value: "reference-config-map"
            - name: REFERENCE_CONFIG_MAP_NAMESPACE
              value: "reference-config-map-namespace"
            - name: TARGET_CONFIG_MAP_NAME
              value: "master-config-map"
            - name: TARGET_CONFIG_MAP_NAMESPACE
              value: "master-config-map-namespace"
            - name: REMOVE_CONFIG
              value: "false"
EOF

kubectl create -n reference-config-map-namespace -f ./add-to-or-update-config-map-job.yaml
```

Define a K8s Job to remove a data element (key-value pair) from a master CM:
```
cat << 'EOF' > remove-data-element-from-config-map-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: remove-data-element-from-config-map-job
spec:
  template:
    metadata:
      name: remove-data-element-from-config-map
    spec:
      restartPolicy: Never
      containers:
        - name: remove-data-element-from-config-map
          image: alexandertgtalbot/kubectl-update-cm-from-cm
          imagePullPolicy: IfNotPresent
          env:
            - name: CUSTOM_CONFIG_NAME
              value: "aRandomKey"
            - name: TARGET_CONFIG_MAP_NAME
              value: "master-config-map"
            - name: TARGET_CONFIG_MAP_NAMESPACE
              value: "master-config-map-namespace"
            - name: REMOVE_CONFIG
              value: "true"
EOF

kubectl create -n reference-config-map-namespace -f ./add-to-or-update-config-map-job.yaml
```

Final cleanup:
```
kubectl delete ns master-config-map-namespace reference-config-map-namespace
```