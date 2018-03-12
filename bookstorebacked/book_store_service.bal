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

package bookstorebacked;

import ballerina.config;
import ballerina.log;
import ballerina.net.http;

// Get the port number from CLI parameters
const int PORT = getPortFromConfig();


// Assign the the service to the PORT
@http:configuration {basePath:"book-store", port:PORT}
service<http> bookStore {

    // Set the resource configurations
    @http:resourceConfig {
        methods:["POST"],
        path:"/"
    }
    resource bookStoreResource (http:Connection conn, http:InRequest req) {
        // Retrieve the book name from the payload
        json requestPayload = req.getJsonPayload();
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
        http:OutResponse outResponse = {};
        outResponse.setJsonPayload(responsePayload);
        _ = conn.respond(outResponse);
    }
}

// Function to receive the port number from the CLI parameters
function getPortFromConfig () (int) {
    // Get the port value as a string
    var portNum = config:getGlobalValue("port");
    // Convert the port number to a integer
    var port, err = <int>portNum;
    // Exit the program if port number is invalid
    if (err != null) {
        log:printError("Error while retriving port number, please add '-Bport = <port_number>' parameter");
        throw err;
    }
    return port;
}