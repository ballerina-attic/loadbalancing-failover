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
import ballerina/log;
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
listener http:Listener bookSearchServiceEP = new(9090);

// Define the load balance client endpoint to call the backend services.
http:LoadBalanceClient bookStoreBackends = new({
    targets: [
        // Create an array of HTTP Clients that needs to be Load balanced across
        { url: "http://localhost:9011/book-store" },
        { url: "http://localhost:9012/book-store" },
        { url: "http://localhost:9013/book-store" }
    ]
});

@http:ServiceConfig {
    basePath: "book"
}
service BookSearch on bookSearchServiceEP {
    @http:ResourceConfig {
        // Set the bookName as a path parameter
        path: "/{bookName}"
    }
    resource function bookSearchService(http:Caller caller, http:Request req, string bookName) {
        // Initialize the request and response messages for the remote call
        http:Request outRequest = new;
        http:Response outResponse = new;

        // Set the json payload with the book name
        json requestPayload = {
            "bookName": bookName
        };
        outRequest.setPayload(untaint requestPayload);
        // Call the book store backend with load balancer
        var backendResponse = bookStoreBackends->post("/", outRequest);
        if (backendResponse is http:Response) {
            //Forward the response received from the book store back end to the client
            var result = caller->respond(backendResponse);
            handleError(result);
        } else {
            //Send the response back to the client if book store back end fails
            var payload = backendResponse.detail().message;
            if (payload is error) {
                outResponse.setPayload("Recursive error occurred while reading backend error");
                handleError(payload);
            } else {
                outResponse.setPayload(string.convert(payload));
            }
            var result = caller->respond(outResponse);
            handleError(result);
        }
    }
}

function handleError(error? result) {
    if (result is error) {
        log:printError(result.reason(), err = result);
    }
}
