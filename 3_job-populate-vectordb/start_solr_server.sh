#!/bin/bash

error() {
    echo "[ERROR]        $*"
    usage
    exit 1
}


usage() {
    echo "Usage:"
    echo "  $(basename "$0") [options]"
    echo "Options:"
    echo "  -h, --help                         display this help"
    echo "  -z=zkhosts                         name of the zookeeper hosts without port and zknode. (default: use embedded zk)"
}

zkhosts=

for i in "$@"
do
case $i in
    -h|--help)
    usage
    exit
    ;;
    -z=*)
    zkhosts="${i#*=}"
    shift
    ;;
    -*)
    error "Unknown option $1"
    ;;
esac
done

VERSION=9.3.0
SOLRTARGZ=solr-${VERSION}.tgz
solr-${VERSION}/bin/solr stop -all
rm -rf solr-${VERSION}
if [ ! -f ${SOLRTARGZ} ]; then
  wget --no-check-certificate "https://www.apache.org/dyn/closer.lua/solr/solr/${VERSION}/solr-${VERSION}.tgz?action=download" -O ${SOLRTARGZ}
fi
tar xfz ${SOLRTARGZ}

if [ ! -z "${zkhosts}" ]; then
  ZK_HOST=${zkhosts}/solr9
  solr-${VERSION}/bin/solr zk rm -r /solr9 -z "${zkhosts}:2181"
  solr-${VERSION}/bin/solr zk mkroot /solr9 -z "${zkhosts}:2181"
fi

ZK_HOST=${ZK_HOST} SOLR_JETTY_HOST="0.0.0.0" SOLR_HOST=$(hostname -f) solr-${VERSION}/bin/solr -c -Dsolr.disableConfigSetsCreateAuthChecks=true -Dsolr.jetty.request.header.size=65535
sleep 5

curl "http://localhost:8983/solr/admin/configs?action=CREATE&name=ampConfigset&baseConfigSet=_default&configSetProp.immutable=false&wt=xml&omitHeader=true"
curl -X POST http://localhost:8983/api/collections -H 'Content-Type: application/json' -d '
  {
    "name": "ampCollection",
    "config": "ampConfigset",
    "numShards": 1
  }
'
curl -X POST -H 'Content-type:application/json' \
  --data-binary '{
    "add-field-type" : {
      "name":"knn_vector",
      "class":"solr.DenseVectorField",
      "vectorDimension":"384",
      "similarityFunction":"euclidean",
      "knnAlgorithm":"hnsw",
      "hnswMaxConnections":"10",
      "hnswBeamWidth":"40"
    }
  }' \
  http://localhost:8983/solr/ampCollection/schema

curl -X POST \
  --url http://localhost:8983/api/collections/ampCollection/schema \
  --header 'Content-Type: application/json' \
  --data '{
    "add-field": [
    {"name": "relativefilepath", "type": "string", "multiValued": false},
    {"name": "embedding", "type": "knn_vector", "indexed":true, "stored":true}
    ]
  }'

