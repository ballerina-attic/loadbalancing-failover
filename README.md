[![Build Status](https://travis-ci.org/rosensilva/loadbalancing-failover.svg?branch=master)](https://travis-ci.org/rosensilva/loadbalancing-failover)
# Load Balancing 
Load balancing is efficiently distributing incoming network traffic across a group of backend servers. The combination of load balancing and failover techniques will create highly available systems that efficiently distribute the workload among all the available resources. Ballerina language supports load balancing by default.

> This guide walks you through the process of adding load balancing for Ballerina programs.

The following are the sections available in this guide.

- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Developing the RESTFul service with load balancing and failover](#developing-the-restful-service-with-a-load-balancer)
- [Testing](#testing)
- [Deployment](#deployment)

## What you'll build

You’ll build a web service with load balancing. To understand this better, you'll be mapping this with a real-world scenario of a book searching service. The book searching service calls one of the three identical bookstore backends to retrieve the book details. With this guide you'll be able to understand how the load balancing mechanism helps to balance the load among all the available remote servers.

![Load Balancer-1](images/loadbalancing-failover-1.svg)
![Load Balancer-2](images/loadbalancing-failover-2.svg)

**Request book details from book search service**: To search for a new book you can use the HTTP GET request that contains the book name as a path parameter.

## Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## Developing the RESTFul service with a load balancer

### Before you begin

#### Understand the package structure
Ballerina is a complete programming language that can have any custom project structure that you wish. Although the language allows you to have any package structure, use the following package structure for this project to follow this guide.

```
└── src
    ├── book_search
    │   ├── book_search_service.bal
    │   └── tests
    │       └── book_search_service_test.bal
    └── book_store_backed
        └── book_store_service.bal

```

The `book_search` is the service that handles the client orders to find books from bookstores. The book search service calls bookstore backends to retrieve book details. You can see that the load balancing technique is applied when the book search service calls one from the three identical backend servers.

The `book_store_backed` service has an independent web service that accepts orders via HTTP POST method from `book_search_service.bal` and sends the details of the book back to the `book_search_service.bal`.

### Implementation of the Ballerina services

#### book_search_service.bal
The `ballerina/net.http` package contains the load balancer implementation. After importing that package you can create an endpoint with a load balancer. The `endpoint` keyword in Ballerina refers to a connection with a remote service. Here you'll have three identical remote services to load balance across. 

First, create an endpoint `bookStoreEndPoints` with the array of HTTP clients that need to be load balanced across. Whenever you call the `bookStoreEndPoints` remote HTTP endpoint, it goes through the load balancer. 

```ballerina
import ballerina/http;

endpoint http:Listener bookSearchServiceEP {
    port:9090
};

// Define the end point to the book store backend
endpoint http:Client bookStoreBackends {
    targets:[
    // Create an array of HTTP Clients that needs to be Load balanced across
        {url:"http://localhost:9011/book-store"},
        {url:"http://localhost:9012/book-store"},
        {url:"http://localhost:9013/book-store"}
    ]
};

@http:ServiceConfig {basePath:"book"}
service<http:Service> bookSearchService bind bookSearchServiceEP {
    @http:ResourceConfig {
        // Set the bookName as a path parameter
        path:"/{bookName}"
    }
    bookSearchService(endpoint conn, http:Request req, string bookName) {
        // Initialize the request and response messages for the remote call
        http:Request outRequest;
        http:Response outResponse;

        // Set the json payload with the book name
        json requestPayload = {"bookName":bookName};
        outRequest.setJsonPayload(requestPayload);
        // Call the book store backend with load balancer
        var backendResponse = bookStoreBackends -> post("/", outRequest);
        // Match the response from the backed to check whether the response received
        match backendResponse {
            // Check the response is a http response
            http:Response inResponse => {
                // forward the response received from book store back end to client
                _ = conn -> respond(inResponse);
            }
            http:HttpConnectorError httpConnectorError => {
                // Send the response back to the client if book store back end fails
                outResponse.statusCode = httpConnectorError.statusCode;
                outResponse.setStringPayload(httpConnectorError.message);
                _ = conn -> respond(outResponse);
            }
        }
    }
}
```

Refer to the complete implementaion of the orderService in the [loadbalancing-failover/booksearchservice/book_search_service.bal](/src/book_search/book_search_service.bal) file.


#### book_store_service.bal
The book store service is a mock service that gives details about the requested book. This service is a simple service that accepts
HTTP POST requests with the following JSON payload.

```json
 {"bookName":"Name of the book"}
```

It then responds with the following JSON.

```json
{
 "Served by Data Ceter" : "1",
 "Book Details" : {
     "Title":"Book titile",
     "Author":"Stephen King",
     "ISBN":"978-3-16-148410-0",
     "Availability":"Available"
 }
}
```

Refer to the complete implementation of the book store service in the [loadbalance-failover/bookstorebacked/book_store_service.bal](src/book_store_backed/book_store_service.bal) file.

## Testing 


### Try it out
#### Load balancer
- Run the book search service by running the following command in the terminal from the `SAMPLE_ROOT/src` directory.
```bash
    $ ballerina run booksearchservice/
```

- Next, run the three instances of the book store service. Here you have to enter the service port number in each service instance. You can pass the port number as parameter `Bport=<Port Number>`.
``` bash
   // 1st instance with port number 9011
   $ ballerina run bookstorebacked/ -Bport=9011
```
   
``` bash
    // 2nd instance with port number 9012
    $ ballerina run bookstorebacked/ -Bport=9012
```
   
``` bash
    // 3rd instance with port number 9013
    $ ballerina run bookstorebacked/ -Bport=9013
```
   With that, all the required services for this guide should be up and running.
  
- Invoke the book search service by sending the following HTTP GET request to the book search service.
```bash
   curl -X GET http://localhost:9090/book/Carrie
```
   You should see a response silmilar to the following.
```json
   {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King"
   ,"ISBN":"978-3-16-148410-   0","Availability":"Available"}}
```
   The`"Served by Data Ceter":1` entry says that the 1st instance of book store backend has been invoked to find the book details.

- Repeat the above request three times. You should see the responses as follows.

```json
   {"Served by Data Ceter":2,"Book Details":{"Title":"Carrie","Author":"Stephen King",
   "ISBN":"978-3-16-148410-   0","Availability":"Available"}}
```

```json
   {"Served by Data Ceter":3,"Book Details":{"Title":"Carrie","Author":"Stephen King",
   "ISBN":"978-3-16-148410-   0","Availability":"Available"}}
```

```json
   {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King",
   "ISBN":"978-3-16-148410-   0","Availability":"Available"}}
```

You can see that the book search service has invoked the book store backed with the round robin load balancing pattern. The `"Served by Data Ceter"` repeats using the following pattern: 1 -> 2 -> 3 -> 1.


#### Load balancer: some servers down

-  Now shut down the third instance of the book store service by terminating the following instance.
```bash
    // 3rd instance with port number 9013
    $ ballerina run bookstorebacked/ -Bport=9013
    // Terminate this from the terminal
``` 
-  Then send following request repeatedly three times,
```bash
    curl -X GET http://localhost:9090/book/Carrie
```  
-  The responses for above requests should look similar to,
```json
    {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King",
    "ISBN":"978-3-16-148410-    0","Availability":"Available"}}
```
```json
    {"Served by Data Ceter":2,"Book Details":{"Title":"Carrie","Author":"Stephen King",
    "ISBN":"978-3-16-148410-   0","Availability":"Available"}}
```
```json
    {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King",
    "ISBN":"978-3-16-148410-   0","Availability":"Available"}}
```
   
- This means that the loadbalancer is preventing the third instance from getting invoked since the third instance is shut down. In the meantime you'll see the order of `"Served by Data Ceter"` is similar to the 1 -> 2 -> 1 pattern.
 
 ### Writing unit tests 

In Ballerina, the unit test cases should be in the same package under the `tests` folder .
The naming convention should be as follows.
* Test files should contain the _test.bal suffix.
* Test functions should contain the test prefix.
  * e.g., testBookStoreService()

This guide contains unit test cases in the respective folders. 

To run the unit tests, go to the `SAMPLE_ROOT/src` and run the following command.
```bash
$ ballerina test
```
## Deployment

Once you are done with the development, you can deploy the service using any of the methods listed below. 

### Deploying locally
You can deploy the RESTful service that you developed above in your local environment. You can create the Ballerina executable archive (.balx) first and then run it in your local environment as follows.

**Building** 
Navigate to `SAMPLE_ROOT/src` and run the following commands
```bash
    $ ballerina build book_store_backed/

    $ ballerina build book_search/
```

**Running**
```bash
    $ ballerina run book_store_backed.balx

    $ ballerina run book_search.balx -Bport=9011
```

### Deploying on Docker

You can run the services that we developed above as a docker container. As Ballerina platform offers native support for running ballerina programs on containers, you just need to put the corresponding docker annotations on your service code. 
Let's see how we can deploy the book_search_service we developed above on docker. 

- In our book_search_service, we need to import  `` import ballerinax/docker; `` and use the annotation `` @docker:Config `` as shown below to enable docker image generation during the build time. 

##### book_search_service.bal
```ballerina
package book_search;

import ballerina/http;
import ballerinax/docker;

@docker:Config {
    registry:"ballerina.guides.io",
    name:"book_search_service",
    tag:"v1.0"
}

endpoint http:ServiceEndpoint bookSearchServiceEP {
    port:9090
};

// http:ClientEndpoint definition for the bookstore backend

@http:ServiceConfig {basePath:"book"}
service<http:Service> bookSearchService bind bookSearchServiceEP {
``` 

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image using the docker annotations that you have configured above. Navigate to the `<SAMPLE_ROOT>/src/` folder and run the following command.  
  
```
  $ballerina build book_search
  
  Run following command to start docker container: 
  docker run -d -p 9090:9090 ballerina.guides.io/book_search_service:v1.0
```
- Once you successfully build the docker image, you can run it with the `` docker run`` command that is shown in the previous step.  

```   
    docker run -d -p 9090:9090 ballerina.guides.io/book_search_service:v1.0
```
    Here we run the docker image with flag`` -p <host_port>:<container_port>`` so that we use the host port 9090 and the container port 9090. Therefore you can access the service through the host port. 

- Verify docker container is running with the use of `` $ docker ps``. The status of the docker container should be shown as 'Up'. 
- You can access the service using the same curl commands that we've used above. 
 
```
   curl -X GET http://localhost:9090/book/Carrie
```


### Deploying on Kubernetes

- You can run the services that we developed above, on Kubernetes. The Ballerina language offers native support for running a ballerina programs on Kubernetes, 
with the use of Kubernetes annotations that you can include as part of your service code. Also, it will take care of the creation of the docker images. 
So you don't need to explicitly create docker images prior to deploying it on Kubernetes.   
Let's see how we can deploy the book_search_service we developed above on kubernetes.

- We need to import `` import ballerinax/kubernetes; `` and use `` @kubernetes `` annotations as shown below to enable kubernetes deployment for the service we developed above. 

##### book_search_service.bal

```ballerina
package book_search;

import ballerina/http;
import ballerinax/kubernetes;

@kubernetes:Ingress {
    hostname:"ballerina.guides.io",
    name:"ballerina-guides-book-search-service",
    path:"/"
}

@kubernetes:Service {
    serviceType:"NodePort",
    name:"ballerina-guides-book-search-service"
}

@kubernetes:Deployment {
    image:"ballerina.guides.io/book_search_service:v1.0",
    name:"ballerina-guides-book-search-service"
}

endpoint http:ServiceEndpoint bookSearchServiceEP {
    port:9090
};

// http:ClientEndpoint definition for the bookstore backend

@http:ServiceConfig {basePath:"book"}
service<http:Service> bookSearchService bind bookSearchServiceEP {
``` 

- Here we have used ``  @kubernetes:Deployment `` to specify the docker image name which will be created as part of building this service. 
- We have also specified `` @kubernetes:Service {} `` so that it will create a Kubernetes service which will expose the Ballerina service that is running on a Pod.  
- In addition we have used `` @kubernetes:Ingress `` which is the external interface to access your service (with path `` /`` and host name ``ballerina.guides.io``)

- Now you can build a Ballerina executable archive (.balx) of the service that we developed above, using the following command. It points to the service file that we developed above and it will create an executable binary out of that. 
This will also create the corresponding docker image and the Kubernetes artifacts using the Kubernetes annotations that you have configured above.
  
```
  $ballerina build book_search
  
  Run following command to deploy kubernetes artifacts:  
  kubectl apply -f ./target/book_search/kubernetes
```

- You can verify that the docker image that we specified in `` @kubernetes:Deployment `` is created, by using `` docker ps images ``. 
- Also the Kubernetes artifacts related our service, will be generated in `` ./target/book_search/kubernetes``. 
- Now you can create the Kubernetes deployment using:

```
 $ kubectl apply -f ./target/book_search/kubernetes 
   deployment.extensions "ballerina-guides-book-search-service" created
   ingress.extensions "ballerina-guides-book-search-service" created
   service "ballerina-guides-book-search-service" created
```

- You can verify Kubernetes deployment, service and ingress are running properly, by using following Kubernetes commands. 
```
$kubectl get service
$kubectl get deploy
$kubectl get pods
$kubectl get ingress
```

- If everything is successfully deployed, you can invoke the service either via Node port or ingress. 

Node Port:
 
```
 curl -X GET http://<Minikube_host_IP>:<Node_Port>/book/Carrie
```
Ingress:

Add `/etc/hosts` entry to match hostname. 
``` 
127.0.0.1 ballerina.guides.io
```

Access the service 

``` 
 curl -X GET http://ballerina.guides.io/book/Carrie 
```
