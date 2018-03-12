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
