savedResponse <- null;

function requestHandler(request, response) {

    savedResponse = response;
    
    try {
        response.header("Access-Control-Allow-Origin", "*");
        
        // check if the app sent relay as a query parameter
        if ("relay" in request.query) {
          if (request.query.relay == "1" || request.query.relay == "2") {
            // convert the relay query parameter to an integer
            local relayState = request.query.relay.tointeger();

            // send "relay" message to device, and send relayState as the data
            device.send("relay", relayState); 
            
            // send a response back saying everything was OK.
            response.send(200, "OK");
        
          } else {
              response.send(500, "Internal Server Error: " + ex);
          }
        }
        // check if the app sent status as a query parameter
        if ("status" in request.query) {
            device.send("getStatus", function() {
                server.log("getStatus called");
            });
        }

    } catch (ex) {
        response.send(500, "Internal Server Error: " + ex);
    }
}

//Listen for when the device reply with door status.
device.on("doorStatus", function(data) {
    server.log("doorStatus Called");

    savedResponse.send(200, data);
});
 
// register the HTTP handler
http.onrequest(requestHandler);