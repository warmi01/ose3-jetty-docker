This project builds an STI jetty builder image for use in Redhat OpenShift 3 environment.

Build the jetty image:

1. Get project code (Git clone from repo)

2. sudo make (in the project directory)

Building the application image with sti:

sudo sti build --context-dir="engine/helloworld" https://github.com/memeinstigator/HelloWorldAppPackage appformer-sti-jetty-builder hello-world-jetty --loglevel=5

Running the container:

sudo docker run -d --name="hello-world-jetty" -v /var/log/jetty-test:/var/log/jetty -p 8080:8080 hello-world-jetty 

Logs:

sudo docker logs -f hello-world-jetty



