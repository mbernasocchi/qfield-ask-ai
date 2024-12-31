import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

Item {
  id: plugin

  property var mainWindow: iface.mainWindow()
  property var mapCanvas: iface.mapCanvas()

  Component.onCompleted: {
    askaiLocatorFilter.locatorBridge.registerQFieldLocatorFilter(askaiLocatorFilter);
  }

  Component.onDestruction: {
    askaiLocatorFilter.locatorBridge.deregisterQFieldLocatorFilter(askaiLocatorFilter);
  }

  QFieldLocatorFilter {
    id: askaiLocatorFilter

    delay: 1000
    name: "askai"
    displayName: "Ask AI"
    prefix: "aai"
    locatorBridge: iface.findItemByObjectName('locatorBridge')

    parameters: {
      "api_url": "https://api.openai.com/v1/chat/completions",
      "service_crs": "EPSG:4326",
      "api_key": ""
     }
    source: Qt.resolvedUrl('askai.qml')
  
    function triggerResult(result) {
      let geometry = result.userData.geometry
      if (geometry.type === Qgis.GeometryType.Point) {
        const centroid = GeometryUtils.reprojectPoint(
          GeometryUtils.centroid(geometry),
          CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"]),
          mapCanvas.mapSettings.destinationCrs
        )
        mapCanvas.mapSettings.setCenter(centroid, true);
      } else {
        const extent = GeometryUtils.reprojectRectangle(
          GeometryUtils.boundingBox(geometry),
          CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"]),
          mapCanvas.mapSettings.destinationCrs
        )
        mapCanvas.mapSettings.setExtent(extent, true);
      }
      
      locatorBridge.locatorHighlightGeometry.qgsGeometry = geometry;
      locatorBridge.locatorHighlightGeometry.crs = CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"]);
    }
  }
}
