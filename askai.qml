import QtQuick
import org.qfield

Item {

  signal prepareResult(var details)
  signal fetchResultsEnded()

  function fetchResults(string, context, parameters) {
    if (parameters["api_url"] === undefined || string === "") {
      fetchResultsEnded();
    }
    console.log('Fetching results.... from ' + parameters["api_url"]);
    //console.log('Context: ' + JSON.stringify(context));

    const isAnthropic = parameters["api_url"].startsWith("https://api.anthropic.com/");

    let request = new XMLHttpRequest();
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        // Parse response JSON
        let json = JSON.parse(request.response)
        let features = FeatureUtils.featuresFromJsonString(isAnthropic ? json["content"][0]["text"] : json["choices"][0]["message"]["content"])
        for (let feature of features) {
          let details = {
            "userData": feature,
            "displayString": feature.attribute('name'),
            "description": feature.attribute('description'),
            "score": 1,
            "groupScore":1,
            "actions":[]
          }
          prepareResult(details);
        }
        fetchResultsEnded()
      }
    }
    
    
    let position = parameters["positionSource"].positionInformation
    console.log('Position: ' + JSON.stringify(context));

    if (string.includes("@me")) {
      if (parameters["positionSource"].active && position.latitudeValid && position.longitudeValid) {
        string = string.replace("@me", `latitude ${position.latitude} and longitude ${position.longitude}`);
      }
       else {
        let details = {
          "userData": null,
          "displayString": "Enable location services to use @me",
          "description": "The @me placeholder feature requires your position to work correctly.",
          "score": 1,
          "groupScore":1,
          "actions":[]
        }
      prepareResult(details);
      fetchResultsEnded();
      return
     }
    }

    console.log('Prompt: ' + string);
    let prompt = string;
    let requestData = {}

    if (isAnthropic) {
      requestData = {
        model: parameters["api_model"],
        max_tokens: 4096,
        messages: [{
            role: "user",
            content: `Generate a GeoJSON object for the following request: ${prompt}.
                     The response should be valid GeoJSON format only, with no additional text.`
        }]
      };
    } else {
      requestData = {
        model: parameters["api_model"],
        messages: [
          {
            role: "developer",
            content: "You should always return valid geojson only" },
          {
            role: "user",
            content: prompt,
          },
        ],
        response_format: {
          type: "json_object",
        }
      };
    }

    console.log('Request data: ' + JSON.stringify(requestData));

    request.open("POST", parameters["api_url"], true);
    if (isAnthropic) {
      request.setRequestHeader('x-api-key', parameters["api_key"]);
      request.setRequestHeader('anthropic-version', '2023-06-01');
    } else {
      request.setRequestHeader("Authorization", `Bearer ${parameters["api_key"]}`);
    }
    request.setRequestHeader('content-type', 'application/json');
    request.send(JSON.stringify(requestData));
  }
}
