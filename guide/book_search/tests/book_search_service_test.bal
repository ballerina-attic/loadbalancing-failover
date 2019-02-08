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
import ballerina/mime;
import ballerina/test;

http:Client httpEndpoint = new("http://localhost:9090/book");

function beforeFunction() {
}

function afterFunction() {
}

@test:Config {
    before: "beforeFunction",
    after: "afterFunction"
}
function testInventoryService() {
    // Initialize the empty http request and response
    http:Request req = new;
    // Test the book search resource
    // Send the request to service and get the response
    var resp = httpEndpoint->post("/Aladin", req);
    if (resp is http:Response) {
        test:assertEquals(resp.statusCode, 200, msg =
            "Book search service didnot respond with 200 OK signal");
    } else if (resp is error) {
        log:printError(resp.reason(), err = resp);
    }
}
