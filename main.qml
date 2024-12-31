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
    property string api_key
  }

  property var mainWindow: iface.mainWindow()
  property var positionSource: iface.findItemByObjectName('positionSource')

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)
  }
  
  QfToolButton {
    id: pluginButton
    iconSource: 'icon.svg'
    iconColor: Theme.mainColor
    bgcolor: Theme.darkGray
    round: true
    
    onClicked: {
      fetchAnswer()
    }
    onPressAndHold: {
            optionDialog.open()
        }
  }

  function fetchAnswer() {
    let parameters = {
      "api_url": settings.api_url,
      "service_crs": "EPSG:4326",
      "api_key": settings.api_key
    }

    let position = positionSource.positionInformation
    if (positionSource.active && position.latitudeValid && position.longitudeValid) {
      mainWindow.displayToast(qsTr('Your current position is ' + position.latitude + ', ' +position.longitude))
    } else {
      mainWindow.displayToast(qsTr('Your current position is unknown\n Not loading POIs nearby'))
      return;
    }
    
    console.log('Fetching results....');

    let prompt = `List interesting tourist attractions near latitude ${position.latitude} and longitude ${position.longitude}.`;
    console.log(prompt);  
    //let prompt = `List interesting tourist attractions near rio de janeiro.`;
    let requestData = {
    model: "gpt-3.5-turbo",
    messages: [
        { role: "developer", content: "You should always return valid geojson only" },
        {
            role: "user", content: prompt,
        },
    ],
    response_format: {
        // could also use /docs/guides/structured-outputs
        type: "json_object",
        }
    }


    let request = new XMLHttpRequest();
    console.log(`Bearer ${parameters["api_key"]}`);
    
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        console.log(request.response)
        
        var response = JSON.parse(request.response)
        if (response.choices && response.choices.length > 0) {
          let content = JSON.stringify(response.choices[0]['message']['content'])
          mainWindow.displayToast(content)
          //console.log(content)
        
        } else {
          mainWindow.displayToast("No response from API")
        }
      }
    }
    //let viewbox = GeometryUtils.reprojectRectangle(context.targetExtent, context.targetExtentCrs, CoordinateReferenceSystemUtils.fromDescription(parameters["service_crs"])).toString().replace(" : ", ",")
    request.open("POST", parameters["api_url"], true);
    request.setRequestHeader("Authorization", `Bearer ${parameters["api_key"]}`);
    request.setRequestHeader("Content-Type", "application/json");
    request.send(JSON.stringify(requestData));
  }
    Dialog {
        id: optionDialog
        parent: mainWindow.contentItem
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("AI settings")

        width: mainWindow.width * 0.8
        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2

        ColumnLayout {
            spacing: 10
            Label {
                id: labelApiUrl
                Layout.fillWidth: true
                text: qsTr("API URL")
            }

            QfTextField {
                id: textFieldApiUrl
                Layout.fillWidth: true
                text: settings.api_url
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
            settings.api_key = textFieldApiKey.text;
            settings.api_url = textFieldApiUrl.text;
            mainWindow.displayToast(qsTr("Settings stored"));
        }
    }
}