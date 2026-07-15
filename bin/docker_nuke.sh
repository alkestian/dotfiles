container_ids=($(docker container ls -q))

if [ ${#container_ids[@]} -eq 0 ]; then 
	exit 0
fi

for id in "${container_ids[@]}"; do
	docker container kill "$id"
done

docker system prune -af --volumes
docker volume prune -af
docker network prune -f
docker image prune -af
docker builder prune -af
