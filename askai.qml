import QtQuick
import org.qfield

Item {

  signal prepareResult(var details)
  signal fetchResultsEnded()

  function fetchResults(string, context, parameters) {
    if (parameters["api_url"] === undefined || string === "") {
      fetchResultsEnded();
    }
    console.log('Fetching results....');

    let request = new XMLHttpRequest();
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        // Parse response JSON
        let json = JSON.parse(request.response)
        let features = FeatureUtils.featuresFromJsonString(json["choices"][0]["message"]["content"])
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

    let prompt = string;
    let requestData = {
      model: "gpt-3.5-turbo",
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

    request.open("POST", parameters["api_url"], true);
    request.setRequestHeader("Authorization", `Bearer ${parameters["api_key"]}`);
    request.setRequestHeader("Content-Type", "application/json");
    request.send(JSON.stringify(requestData));
  }
}
