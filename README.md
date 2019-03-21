# Kubernetes Azure Playground

## nodejs test service

### run without docker

```
yarn start
```

http://localhost:5010/

### run in docker

```
docker-compose up

or

docker-compose up --force-recreate --build
```

http://localhost:8090/

## dotnetcore test service

### run without docker

```
dotnet run --project TestSvc/TestSvc.csproj
```

http://localhost:5000/

### run in docker

```
docker-compose up

or

docker-compose up --force-recreate --build
```

http://localhost:8080/

## create container registry & cluster

### setup

1. `cp .env.template .env`
1. configure .env
1. install azure cli, `brew update && brew install azure-cli`
1. login into azure cli
   1. `az account show`
   1. `az login`
   1. `az account show`

### container registry

```
bash container-registry/build.sh
```

### cluster

```
bash cluster/build.sh
```

## delete all

### cluster

```
bash cluster/teardown.sh
```

### container registry

```
bash container-registry/delete.sh
```
