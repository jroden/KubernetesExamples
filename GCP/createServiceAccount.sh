# create gcp role and service account for read only kubernetes permissions
# this service account would be assumed by other GCP services that require gke read permissions
project_id=$1
role_name=kubernetes_developer
srv_name=kubernetes-read-only

# read only role has permissions to list gke clusters
gcloud iam roles create $role_name --project $project_id \
  --title=kubernetes_developer --description "kubernetes read only role" \
  --permissions=container.clusters.list,container.clusters.get --stage=Alpha

# create service account
gcloud iam service-accounts create $srv_name \
    --description="read only srv for gke" \
    --display-name="kubernetes-read-only"

# add the read only role to the service account
gcloud projects add-iam-policy-binding $project_id \
  --member serviceAccount:"$srv_name"@"$project_id".iam.gserviceaccount.com \
  --role projects/"$project_id"/roles/"$role_name"

# pull the key file (not shown here) and activate srv for testing permissions
gcloud auth activate-service-account --key-file=$key_file

# get name of cluster
gcloud container clusters list

# update kubeconfig with srv credentials
gcloud container clusters get-credentials examplecluster  # examplecluster determined from previous command

# test access
kubectl get pods -n development
