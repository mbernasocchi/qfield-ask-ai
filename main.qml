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
    prefix: "ai"
    locatorBridge: iface.findItemByObjectName('locatorBridge')

    parameters: {
      "api_url": "https://api.openai.com/v1/completions",
      "service_crs": "EPSG:4326",
      "api_key": "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";

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

    function triggerResultFromAction(result, actionId) {
      if (actionId === 1) {
        let navigation = iface.findItemByObjectName('navigation')
        let geometry = result.userData.geometry
        const centroid = GeometryUtils.reprojectPoint(
          GeometryUtils.centroid(geometry),
          CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"]),
          mapCanvas.mapSettings.destinationCrs
        )
        navigation.destination = centroid
      } else if (actionId === 2) {
        let feature = result.userData
        Qt.openUrlExternally("tel:" + feature.attribute("extratags")["phone"].replace(' ',''))
      }
    }
  }
}
