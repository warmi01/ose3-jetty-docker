IMAGE_NAME = appformer-sti-jetty-builder

build:
		docker build -t $(IMAGE_NAME) .
