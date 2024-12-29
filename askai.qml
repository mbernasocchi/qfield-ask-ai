import QtQuick
import org.qfield

Item {
  signal prepareResult(var details)
  signal fetchResultsEnded()

  let latitude = qfield.gpsPosition.coordinate.latitude;
  let longitude = qfield.gpsPosition.coordinate.longitude;


  
  function fetchResults(string, context, parameters) {
    if (parameters["api_url"] === undefined || string === "") {
      fetchResultsEnded();
    }
    console.log('Fetching results....');

    //let prompt = `List interesting tourist attractions near latitude ${latitude} and longitude ${longitude}.`;
    let requestData = {
        model: "text-davinci-003",
        prompt: string,
        max_tokens: 150,
    };

    let request = new XMLHttpRequest();
    request.setRequestHeader("Authorization", `Bearer ${parameters["api_key"]}`);
    request.setRequestHeader("Content-Type", "application/json");

    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        //let features = FeatureUtils.featuresFromJsonString(request.response)
        let details = JSON.parse(request.response)    
        prepareResult(details);
        fetchResultsEnded()
      }
    }
    let viewbox = GeometryUtils.reprojectRectangle(context.targetExtent, context.targetExtentCrs, CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"])).toString().replace(" : ", ",")
    request.open("POST", parameters["api_url"], true)
    request.send(JSON.stringify(requestData));
  }
}
