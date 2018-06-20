// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
//import ballerinax/docker;
//import ballerinax/kubernetes;

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"book_search_service",
//    tag:"v1.0"
//}

//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-book-search-service",
//    path:"/"
//}
//
//@kubernetes:Service {
//    serviceType:"NodePort",
//    name:"ballerina-guides-book-search-service"
//}
//
//@kubernetes:Deployment {
//    image:"ballerina.guides.io/book_search_service:v1.0",
//    name:"ballerina-guides-book-search-service"
//}

// Create an endpoint with port 9090 for the book search service
endpoint http:Listener bookSearchServiceEP {
    port: 9090
};

// Define the load balance client endpoint to call the backend services.
endpoint http:LoadBalanceClient bookStoreBackends {
    targets: [
    // Create an array of HTTP Clients that needs to be Load balanced across
        { url: "http://localhost:9011/book-store" },
        { url: "http://localhost:9012/book-store" },
        { url: "http://localhost:9013/book-store" }
    ]
};

@http:ServiceConfig { basePath: "book" }
service<http:Service> BookSearch bind bookSearchServiceEP {
    @http:ResourceConfig {
        // Set the bookName as a path parameter
        path: "/{bookName}"
    }
    bookSearchService(endpoint conn, http:Request req, string bookName) {
        // Initialize the request and response messages for the remote call
        http:Request outRequest;
        http:Response outResponse;

        // Set the json payload with the book name
        json requestPayload = { "bookName": bookName };
        outRequest.setJsonPayload(requestPayload);
        // Call the book store backend with load balancer
        var backendResponse = bookStoreBackends->post("/", outRequest);
        // Match the response from the backed to check whether the response received
        match backendResponse {
            // Check the response is a http response
            http:Response inResponse => {
                // forward the response received from book store back end to client
                _ = conn->respond(inResponse);
            }
            error httpConnectorError => {
                // Send the response back to the client if book store back end fails
                outResponse.setTextPayload(httpConnectorError.message);
                _ = conn->respond(outResponse);
            }
        }
    }
}
