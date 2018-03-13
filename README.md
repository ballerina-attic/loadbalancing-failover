# Load Balancing 
Load Balancing is efficiently distributing incoming network traffic across a group of backend servers. The combination of load balancing and failover techniques will create highly available systems with efficiently distributing the workload among all the available resources. Ballerina language supports load balancing out-of-the-box.

> This guide walks you through the process of adding load balancing for Ballerina programmes.

The following are the sections available in this guide.

- [What you'll build](#what-you-build)
- [Prerequisites](#pre-req)
- [Developing the RESTFul service with load balancing and failover](#developing-service)
- [Testing](#testing)
- [Deployment](#deploying-the-scenario)
- [Observability](#observability)

## <a name="what-you-build"></a>  What you'll build

You’ll build a web service with load balancing. To understand this better, you'll be mapping this with a real-world scenario of a book searching service. The book searching service will call one from the three identical bookstore backends to retrieve the book details. With this guide you'll be able to understand how the load balancing mechanism helps to balance the load among all the available remote servers.

![Load Balancer](images/load_balancer_image1.png)

**Request book details from book search service**: To search a new book you can use the HTTP GET request that contains the book name as a path parameter.

## <a name="pre-req"></a> Prerequisites
 
- JDK 1.8 or later
- [Ballerina Distribution](https://github.com/ballerina-lang/ballerina/blob/master/docs/quick-tour.md)
- A Text Editor or an IDE 

### Optional requirements
- Ballerina IDE plugins ([IntelliJ IDEA](https://plugins.jetbrains.com/plugin/9520-ballerina), [VSCode](https://marketplace.visualstudio.com/items?itemName=WSO2.Ballerina), [Atom](https://atom.io/packages/language-ballerina))
- [Docker](https://docs.docker.com/engine/installation/)

## <a name="developing-service"></a> Developing the RESTFul service with Load Balancer

### Before you begin

#### Understand the package structure
The project structure for this guide should be as the following.

```
├── booksearchservice
│   └── book_search_service.bal
└── bookstorebacked
    └── book_store_service.bal
```

The `booksearchservice` is the service that handles the client orders to find books from bookstores. Book search service call bookstore backends to retrieve book details. You can see that the loadbalancing technique is applied when the book search service calls one from the three identical backend servers.

The `bookstorebacked` is an independent web service that accepts orders via HTTP POST method from `booksearchservice` and sends the details of the book back to the `booksearchservice`.

### Implementation of the Ballerina services

#### book_search_service.bal
The `ballerina.net.http.resiliency` package contains the load balancer implementation. After importing that package you can create an endpoint with a load balancer. The `endpoint` keyword in Ballerina refers to a connection with a remote service. Here you'll have three identical remote services to load balance across. First, create a LoadBalancer end point by ` create resiliency:LoadBalancer` statement. Then you need to create an array of HTTP Clients that you needs to be Loadbalanced across. Finally, pass the `resiliency:roundRobin` argument to the `create loadbalancer` constructor. Now whenever you call the `bookStoreEndPoints` remote HTTP endpoint, it goes through the load balancer. 

```ballerina
package booksearchservice;

import ballerina.net.http.resiliency;
import ballerina.net.http;


@http:configuration {basePath:"book"}
service<http> bookSearchService {
    @http:resourceConfig {
    // Set the bookName as a path parameter
        path:"/{bookName}"
    }
    resource bookSearchService (http:Connection conn, http:InRequest req, string bookName) {
        // Define the end point to the book store backend
        endpoint<http:HttpClient> bookStoreEndPoints {
        // Crate a LoadBalancer end point
        // The LoadBalancer is defined in ballerina.net.http.resiliency package
            create resiliency:LoadBalancer(
            // Create an array of HTTP Clients that needs to be Loadbalanced across
            [create http:HttpClient("http://localhost:9011/book-store", {endpointTimeout:1000}),
             create http:HttpClient("http://localhost:9012/book-store", {endpointTimeout:1000}),
             create http:HttpClient("http://localhost:9013/book-store", {endpointTimeout:1000})],
            // Use the round robbin load balancing algorithm
            resiliency:roundRobin);
        }

        // Initialize the request and response messages for the remote call
        http:InResponse inResponse = {};
        http:HttpConnectorError httpConnectorError;
        http:OutRequest outRequest = {};

        // Set the json payload with the book name
        json requestPayload = {"bookName":bookName};
        outRequest.setJsonPayload(requestPayload);
        // Call the book store backend with loadbalancer enabled
        inResponse, httpConnectorError = bookStoreEndPoints.post("/", outRequest);
        // Send the response back to the client
        http:OutResponse outResponse = {};
        if (httpConnectorError != null) {
            outResponse.statusCode = httpConnectorError.statusCode;
            outResponse.setStringPayload(httpConnectorError.message);
            _ = conn.respond(outResponse);
        } else {
            _ = conn.forward(inResponse);
        }
    }
}

```

Refer to the complete implementaion of the orderService in the [loadbalancing-failover/booksearchservice/book_search_service.bal](/booksearchservice/book_search_service.bal) file.


#### book_store_service.bal
The book store service is a mock service that gives the details about the requested book. This service is a simple service that accepts,
HTTP POST requests with following json payload
```json
 {"bookName":"Name of the book"}
```
and resopond with the following JSON,

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

Refer to the complete implementation of the book store service in the [loadbalance-failover/bookstorebacked/book_store_service.bal](bookstorebacked/book_store_service.bal) file.

## <a name="testing"></a> Testing 


### Try it out
#### Load balancer
1. Run book search service by running the following command in the terminal from the sample root directory.
    ```bash
    $ ballerina run booksearchservice/
   ```

2. Next, run the three instances of the book store service. Here you have to enter the service port number in each service instance. You can pass the port number as parameter `Bport=<Port Number>`
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
   With that all the required services for this guide should be up and runninig.
  
3. Invoke the book search service by sending the following HTTP GET request to the book search service
 
   ```bash
   curl -X GET http://localhost:9090/book/Carrie
   ```
   You should see a response silmilar to,
   ```json
   {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-   0","Availability":"Available"}}
   ```
   The`"Served by Data Ceter":1` entry says that 1st instance of book store backend has invoked to find the book details

4. Repeat the above request for three times. You should see the responses as follows,

   ```json
   {"Served by Data Ceter":2,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-   0","Availability":"Available"}}
   ```
   ```json
   {"Served by Data Ceter":3,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-   0","Availability":"Available"}}
   ```
   ```json
   {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-   0","Availability":"Available"}}
   ```

  You can see that the book search service has invoked book store backed with round robin load balancing pattern. The `"Served by Data Ceter"` is repeating as 1 -> 2 -> 3 -> 1 pattern.


#### Load balancer: some servers down

1.  Now shut down the 3rd instance of the book store service by terminating following instance,
    ```bash
    // 3rd instance with port number 9013
    $ ballerina run bookstorebacked/ -Bport=9013
    // Terminate this from the terminal
    ``` 
2.  Then send following request repeatedly for three times,

    ```bash
    curl -X GET http://localhost:9090/book/Carrie
    ```  
3.  The responses for above requests should look similar to,
    ```json
    {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-    0","Availability":"Available"}}
    ```
    ```json
    {"Served by Data Ceter":2,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-   0","Availability":"Available"}}
    ```
    ```json
    {"Served by Data Ceter":1,"Book Details":{"Title":"Carrie","Author":"Stephen King","ISBN":"978-3-16-148410-   0","Availability":"Available"}}
    ```
   
 3.  This means that the loadbalancer is preventing the 3rd instance form invoking since we have shut down the 3rd instance. Meantime you'll see the order of `"Served by Data Ceter"` is similar to 1 -> 2 -> 1 pattern.
 
 ### <a name="unit-testing"></a> Writing unit tests 

In Ballerina, the unit test cases should be in the same package and the naming convention should be as follows,
* Test files should contain the _test.bal suffix.
* Test functions should contain the test prefix.
  * e.g., testBookStoreService()

This guide contains unit test cases in the respective folders. 
To run the unit tests, go to the sample root directory and run the following command
```bash
$ ballerina test bookstorebacked/
```
```bash
$ ballerina test booksearchservice/
```
## <a name="deploying-the-scenario"></a> Deployment

Once you are done with the development, you can deploy the service using any of the methods listed below. 

### <a name="deploying-on-locally"></a> Deploying locally
You can deploy the RESTful service that you developed above in your local environment. You can create the Ballerina executable archive (.balx) first and then run it in your local environment as follows.

Building 
   ```bash
    $ ballerina build booksearchservice/

    $ ballerina build bookstorebacked/

   ```

Running
   ```bash
    $ ballerina run booksearchservice.balx

    $ ballerina run bookstorebacked.balx -Bport=9011

   ```

### <a name="deploying-on-docker"></a> Deploying on Docker
(Work in progress) 

### <a name="deploying-on-k8s"></a> Deploying on Kubernetes
(Work in progress) 


## <a name="observability"></a> Observability 

### <a name="logging"></a> Logging
(Work in progress) 

### <a name="metrics"></a> Metrics
(Work in progress) 


### <a name="tracing"></a> Tracing 
(Work in progress) 
