import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtCore

import org.qfield
import org.qgis
import Theme


Item {
  id: plugin
  
  Settings {
    id: settings
    property string api_url: "https://api.openai.com/v1/chat/completions"
    property string api_key: "KEYYYYY"
  }

  property var mainWindow: iface.mainWindow()
  property var mapCanvas: iface.mapCanvas()
  property var positionSource: iface.findItemByObjectName('positionSource')
  property var locatorItem: iface.findItemByObjectName('locatorItem')

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)

    askaiLocatorFilter.locatorBridge.registerQFieldLocatorFilter(askaiLocatorFilter);
  }

  QFieldLocatorFilter {
    id: askaiLocatorFilter

    delay: 1000
    name: "askai"
    displayName: "Ask AI"
    prefix: "aai"
    locatorBridge: iface.findItemByObjectName('locatorBridge')

    parameters: {
      "api_url": settings.api_url,
      "api_key": settings.api_key,
      "service_crs": "EPSG:4326",
    }
    source: Qt.resolvedUrl('askai.qml')

    function triggerResult(result) {
      let geometry = result.userData.geometry
      if (geometry.type === Qgis.GeometryType.Point) {
        const centroid = GeometryUtils.reprojectPoint(
                         GeometryUtils.centroid(geometry),
                         CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"),
                         mapCanvas.mapSettings.destinationCrs
                         )
        mapCanvas.mapSettings.setCenter(centroid, true);
      } else {
        const extent = GeometryUtils.reprojectRectangle(
                       GeometryUtils.boundingBox(geometry),
                       CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"),
                       mapCanvas.mapSettings.destinationCrs
                       )
        mapCanvas.mapSettings.setExtent(extent, true);
      }

      locatorBridge.locatorHighlightGeometry.qgsGeometry = geometry;
      locatorBridge.locatorHighlightGeometry.crs = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326");
    }
  }

  QfToolButton {
    id: pluginButton
    iconSource: 'icon.svg'
    iconColor: Theme.mainColor
    bgcolor: Theme.darkGray
    round: true
    
    onClicked: {
      let position = positionSource.positionInformation
      if (positionSource.active && position.latitudeValid && position.longitudeValid) {
        mainWindow.displayToast(qsTr('Your current position is ' + position.latitude + ', ' +position.longitude))
      } else {
        mainWindow.displayToast(qsTr('Your current position is unknown\n Not loading POIs nearby'))
        return;
      }

      // TODO: Find a way to paste content into the search bar directly.
      let prompt = `aai List interesting tourist attractions near latitude ${position.latitude} and longitude ${position.longitude}.`;
      platformUtilities.copyTextToClipboard(prompt);
      mainWindow.displayToast(qsTr("Prompt copied to clipboard, paste it into the search bar!"))
    }
    onPressAndHold: {
      optionDialog.open()
    }
  }

  Dialog {
    id: optionDialog
    parent: mainWindow.contentItem
    visible: false
    modal: true
    font: Theme.defaultFont
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: qsTr("AI settings")

    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height) / 2

    ColumnLayout {
      spacing: 10

      Label {
        id: labelApiKey
        text: qsTr("API key")
      }

      QfTextField {
        id: textFieldApiKey
        Layout.fillWidth: true
        text: settings.api_key
      }
      Label {
        id: labelApiUrl
        text: qsTr("API URL")
      }

      QfTextField {
        id: textFieldApiUrl
        Layout.fillWidth: true
        text: settings.api_url
      }
    }

    onAccepted: {
      settings.api_key = textFieldApiKey.text;
      settings.api_url = textFieldApiUrl.text;
      mainWindow.displayToast(qsTr("Settings stored"));
    }
  }
}
