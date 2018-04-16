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

package book_store_backed;

import ballerina/config;
import ballerina/log;
import ballerina/http;
import ballerina/io;

// Get the port number from CLI parameters
@final int PORT = getPortFromConfig();

// Create the endpoint with the PORT from CLI arguments
endpoint http:Listener bookStoreEP {
    port:9011
};

// Set the basepath to the service
@http:ServiceConfig {basePath:"/book-store"}
service<http:Service> bookStore bind bookStoreEP {

// Set the resource configurations
    @http:ResourceConfig {
        methods:["POST"],
        path:"/"
    }
    bookStoreResource(endpoint conn, http:Request req) {
        // Retrieve the book name from the payload
        json requestPayload = check req.getJsonPayload();
        json bookTitle = requestPayload.bookName;
        // Populate the output data with mock book details
        json responsePayload = {
            // Set the DataCenter number as last digit of the PORT
            "Served by Data Ceter":PORT % 10,
            "Book Details":{
                "Title":bookTitle,
                "Author":"Stephen King",
                "ISBN":"978-3-16-148410-0",
                "Availability":"Available"
            }
        };
        // Set the payload and send the results to the client
        http:Response outResponse;
        outResponse.setJsonPayload(responsePayload);
        _ = conn -> respond(outResponse);
    }
}

// Function to receive the port number from the CLI parameters
function getPortFromConfig() returns (int) {
    // Get the port value as a string
    var usersConfig = config:getAsString("port");

    // Convert the port number to a integer
    var result = <int>usersConfig;
    // Check weather the PORT number is an Int
    match result {
        // Return port number if the portNumber converted to int successfully
        int port => {
            return port;
        }
        // Throw an error if port number is invalid
        error err => {
            log:printError("Error while retriving port number, please add '-Bport = <port_number>' parameter");
            throw err;
        }
    }
}

