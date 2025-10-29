fter run installarion.sh 

gcloud compute ssh redis-proxy \
  --zone=us-east1-a \
  -- -L 172.17.0.1:6379:110.0.0.4:6379

now your can see this redis into your clusyter


