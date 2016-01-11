#!/bin/bash

TAG=$1

RESULT=0

DOCKERFILE_PATH=""
OLD_IMAGE_NAME="ca/platform_jettyimage"
IMAGE_NAME="platform/jetty-sti"

# Cleanup the temporary Dockerfile created by docker build with version
trap 'remove_tmp_dockerfile' SIGINT SIGQUIT EXIT
function remove_tmp_dockerfile {
  if [[ ! -z "${DOCKERFILE_PATH}.version" ]]; then
    rm -f "${DOCKERFILE_PATH}.version"
  fi
}

# Perform docker build but append the LABEL with GIT commit id at the end
function docker_build_with_version {
  local dockerfile="$1"
  # Use perl here to make this compatible with OSX
  DOCKERFILE_PATH=$(perl -MCwd -e 'print Cwd::abs_path shift' $dockerfile)
  cp ${DOCKERFILE_PATH} "${DOCKERFILE_PATH}.version"
  git_version=$(git rev-parse --short HEAD)
  echo "LABEL io.openshift.builder-version=\"${git_version}\"" >> "${dockerfile}.version"
  echo "Running docker build to create image ${IMAGE_NAME}:${TAG}"  
  docker build --force-rm -t ${IMAGE_NAME}:${TAG} -f "${dockerfile}.version" .
  RESULT=$?
  echo "Docker build finished with ${RESULT}"
}

function docker_login {
  RESULT=0
  local artifactory_param="$1"
  local artifactory_api_param="$2"
  
  if [ "${artifactory_api_param}" = "v2" ]; then
    echo "Running docker login with ${artifactory_param}/${artifactory_api_param}"
    docker login --username=${ARTIFACTORY_USER} --password=${ARTIFACTORY_PASS} --email=${ARTIFACTORY_EMAIL} "${artifactory_param}/${artifactory_api_param}"
    RESULT=$?
  fi
}

function docker_tag_with_version {
  local image_name_source="$1" 
  local image_tag_source="$2"
  local artifactory_host="$3"
  local image_name_destination="$4"   
  local image_tag_destination="$5"
  echo "Running image tagging on ${image_name_source}:${image_tag_source} with tag ${artifactory_host}/${image_name_destination}:${image_tag_destination}"
  docker tag -f "${image_name_source}:${image_tag_source}" "${artifactory_host}/${image_name_destination}:${image_tag_destination}" 
  RESULT=$?
  echo "Tagging image finished with ${RESULT}"
}

function docker_push_with_version {
  local artifactory_host="$1"
  local image_name="$2" 
  local image_tag="$3"
  
  echo "Running docker push on image ${artifactory_host}/${image_name}:${image_tag}"
  docker push "${artifactory_host}/${image_name}:${image_tag}"
  RESULT=$?
  echo "Pushing image to docker factory finished with ${RESULT}"
}

function docker_tag_login_push {
  local image_name_source="$1"
  local image_name_destination="$2"
  local image_tag="$3"  
  local artifactory_name="$4"  
  local artifactory_api_version="$5"  
  
  if [[ $RESULT -eq 0 ]] ; then
      docker_tag_with_version $image_name_source $image_tag $artifactory_name $image_name_destination $image_tag
  fi

  if [[ $RESULT -eq 0 ]] ; then
      docker_login $artifactory_name $artifactory_api_version
  fi
    
  if [[ $RESULT -eq 0 ]] ; then
      docker_push_with_version $artifactory_name $image_name_destination $image_tag 
  fi
}

function docker_remove_images {
    echo "Removing built images from local docker"
    docker rmi -f "${ARTIFACTORY}/${BASE_IMAGE_NAME}:${TAG}" 2>/dev/null
    docker rmi -f "${TEST_IMAGE_NAME}:${TAG}" 2>/dev/null
    docker rmi -f "${BASE_IMAGE_NAME}:${TAG}" 2>/dev/null
    docker rmi -f "docker.io/openshift/base-centos7" 2>/dev/null
}

# Remove the images if they did not get wiped from some reason by the previous build
docker_remove_images

echo "-> Building ${IMAGE_NAME} ..."

docker_build_with_version Dockerfile

if [[ $RESULT -eq 0 ]] ; then 
    if [[ $ARTIFACTORY_PUSH = "true" ]] && [[ ! -z "$TAG" ]] && [[ ! -z "$ARTIFACTORY" ]] && [[ ! -z "$ARTIFACTORY_API_VERSION" ]]; then
        docker_tag_login_push $IMAGE_NAME $OLD_IMAGE_NAME $TAG $ARTIFACTORY $ARTIFACTORY_API_VERSION
    fi
    if [[ $ARTIFACTORY_PUSH = "true" ]] && [[ ! -z "$TAG" ]] && [[ ! -z "$ARTIFACTORY2" ]] && [[ ! -z "$ARTIFACTORY2_API_VERSION" ]]; then
        docker_tag_login_push $IMAGE_NAME $IMAGE_NAME $TAG $ARTIFACTORY2 $ARTIFACTORY2_API_VERSION
    fi  
fi

# Remove images if something failed and they remained in docker
docker_remove_images

echo "Building image finished with ${RESULT}"
exit $RESULT