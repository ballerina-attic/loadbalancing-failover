package book_search;

import ballerina/http;
import ballerina/test;
import ballerina/mime;

endpoint http:Client httpEndpoint {
    targets:[
            {
                url:"http://localhost:9090/book"
            }
            ]
};

function beforeFunction () {
    // Start the book search service
    _ = test:startServices("book_search");
}

function afterFunction () {
    // Stop the book search service
    test:stopServices("book_search");
}

@test:Config {
    before:"beforeFunction",
    after:"afterFunction"
}
function testInventoryService () {
    // Initialize the empty http request and response
    http:Request req;
    // Test the book search resource
    // Send the request to service and get the response
    http:Response resp = check httpEndpoint -> post("/Aladin", req);
    test:assertEquals(resp.statusCode, 500, msg = "Book search service didnot respond with 200 OK signal");
    var result = resp.getStringPayload();
    match result {
        string responseString => {
        // Test the responses from the service with the original test data
            test:assertTrue(responseString.contains("All the load balance endpoints failed"),
                            msg = "respond mismatch");

        }
        mime:EntityError| () => { return; }
    }
}


