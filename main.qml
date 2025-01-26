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
    property string api_url: "https://api.anthropic.com/v1/messages" //"https://api.openai.com/v1/chat/completions"
    property string api_model: "claude-3-5-sonnet-20241022" //"gpt-3.5-turbo"
    property string api_key
    property string last_prompt
  }

  function configure() {
    optionDialog.open();
  }


  property var mainWindow: iface.mainWindow()
  property var mapCanvas: iface.mapCanvas()
  property var positionSource: iface.findItemByObjectName('positionSource')

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
      "api_model": settings.api_model,
      "api_key": settings.api_key,
      "position_information": positionSource.active ? positionSource.positionInformation : undefined
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
      const position = positionSource.positionInformation
      if (positionSource.active && position.latitudeValid && position.longitudeValid) {
        mainWindow.displayToast(qsTr('Your current position is ' + position.latitude + ', ' +position.longitude))
      } else {
        mainWindow.displayToast(qsTr('Your current position is unknown\nContext variables will only work partially'))
      }
      promptDialog.open()
    }
    onPressAndHold: {
      optionDialog.open()
    }
  }

  Dialog {
    id: promptDialog
    parent: mainWindow.contentItem
    visible: false
    modal: true
    font: Theme.defaultFont
    standardButtons: Dialog.Ok | Dialog.Cancel
    title: qsTr("AI prompt")

    x: (mainWindow.width - width) / 2
    y: (mainWindow.height - height) / 2

    height: mainWindow.height * 0.6
    width: mainWindow.width * 0.8

    RowLayout {
      width: parent.width
      height: parent.height
      spacing: 10
      
      TextArea {
        id: textAreaPrompt
        Layout.fillWidth: true
        Layout.fillHeight: true
        text: settings.last_prompt
      }
      ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: 10
        Label {
          text: qsTr("Context variables")
        }
        QfButton {
          text: qsTr("@me")
          onClicked: {
            textAreaPrompt.text += " @me"
            textAreaPrompt.cursorPosition = textAreaPrompt.text.length
            }
        }
        QfButton {
          text: qsTr("@mapcenter")
          onClicked: {
            textAreaPrompt.text += " @mapcenter"
            textAreaPrompt.cursorPosition = textAreaPrompt.text.length
        }
        }
        QfButton {
          text: qsTr("@mapextent")
          onClicked: {
            textAreaPrompt.text += " @mapextent"
            textAreaPrompt.cursorPosition = textAreaPrompt.text.length
          }
        }
        Label {
          text: qsTr("Prompts")
        }
        QfButton {
          text: qsTr("Generate random")
          onClicked: {
            const poi_types = ["restaurants", "museums", "parks", "historical sites", "shopping centers"]
            const poi_type = poi_types[Math.floor(Math.random() * poi_types.length)]
            const poi_relations = ["near @me", "around @mapcenter", "within @mapextent"]
            const poi_relation = poi_relations[Math.floor(Math.random() * poi_relations.length)]
            const prompt = `List interesting ${poi_type} ${poi_relation}.`;
            textAreaPrompt.text = prompt
            textAreaPrompt.cursorPosition = textAreaPrompt.text.length
          }
        }
        QfButton {
          text: qsTr("Reload last")
          onClicked: {
            textAreaPrompt.text = settings.last_prompt
            textAreaPrompt.cursorPosition = textAreaPrompt.text.length
          }
        }
      }
    }

    onAccepted: {
      settings.last_prompt = textAreaPrompt.text;
      askaiLocatorFilter.locatorBridge.requestSearch("AAI " + textAreaPrompt.text)
    }

    Component.onCompleted: {
      textAreaPrompt.focus = true
      promptDialog.standardButton(Dialog.Ok).text = qsTr("Ask AI!")
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

    width: mainWindow.width * 0.8

    ColumnLayout {
      width: parent.width
      spacing: 10
      
      Label {
        id: labelApiUrl
        text: qsTr("API URL")
      }

      QfComboBox {
        id: textFieldApiUrl
        Layout.fillWidth: true
        model: ["https://api.anthropic.com/v1/messages", "https://api.openai.com/v1/chat/completions"]
        currentIndex: settings.api_url === "https://api.anthropic.com/v1/messages" ? 0 : 1

        onCurrentIndexChanged: {
          textFieldApiModel.text = currentIndex === 0 ? "claude-3-5-sonnet-20241022" : "gpt-3.5-turbo"
        }
      }
      
      Label {
        id: labelApiModel
        text: qsTr("API model")
      }

      QfTextField {
        id: textFieldApiModel
        Layout.fillWidth: true
        text: settings.api_model
      }

      Label {
        id: labelApiKey
        Layout.fillWidth: true
        text: qsTr("API key")
      }

      QfTextField {
        id: textFieldApiKey
        Layout.fillWidth: true
        text: settings.api_key
      }
      
    }

    onAccepted: {
      settings.api_url = textFieldApiUrl.currentText;
      settings.api_model = textFieldApiModel.text;
      settings.api_key = textFieldApiKey.text;
      mainWindow.displayToast(qsTr("Settings stored"));
    }
  }
}
