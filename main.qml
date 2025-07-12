import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtCore

import org.qfield
import org.qgis
import Theme

import "config.js" as CONFIG

Item {
    id: plugin

    Settings {
        id: settings
        category: "ask-ai"

        property string api_url: CONFIG.apis[0]["url"]
        property string api_model: CONFIG.apis[0]["models"][0] 
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
        iface.addItemToPluginsToolbar(pluginButton);

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

        Component.onCompleted: {
            if (askaiLocatorFilter.description !== undefined) {
                askaiLocatorFilter.description = "Returns a list of LLM generated search results with spatial locations."
            }
        }

        function triggerResult(result) {
            let geometry = result.userData.geometry;
            if (geometry.type === Qgis.GeometryType.Point) {
                const centroid = GeometryUtils.reprojectPoint(GeometryUtils.centroid(geometry), CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"), mapCanvas.mapSettings.destinationCrs);
                mapCanvas.mapSettings.setCenter(centroid, true);
            } else {
                const extent = GeometryUtils.reprojectRectangle(GeometryUtils.boundingBox(geometry), CoordinateReferenceSystemUtils.fromDescription("EPSG:4326"), mapCanvas.mapSettings.destinationCrs);
                mapCanvas.mapSettings.setExtent(extent, true);
            }

            locatorBridge.geometryHighlighter.qgsGeometry = geometry;
            locatorBridge.geometryHighlighter.crs = CoordinateReferenceSystemUtils.fromDescription("EPSG:4326");
        }
    }

    QfToolButton {
        id: pluginButton
        iconSource: 'icon.svg'
        iconColor: Theme.mainColor
        bgcolor: Theme.darkGray
        round: true

        onClicked: {
            const position = positionSource.positionInformation;
            if (!positionSource.active || !position.latitudeValid || !position.longitudeValid) {
                mainWindow.displayToast(qsTr('Your current position is unknown\nContext variables will only work partially'));
            }
            promptDialog.open();
        }
        onPressAndHold: {
            optionDialog.open();
        }
    }

    Dialog {
        id: promptDialog
        parent: mainWindow.contentItem
        visible: false
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("AI prompt builder")

        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2

        height: mainWindow.height * 0.6
        width: mainWindow.width * 0.8

        property bool isReadyToPrompt: settings.api_url != "" && settings.api_model != "" && settings.api_key != ""
        
        ColumnLayout {
            width: parent.width
            height: parent.height
            spacing: 10
            
            RowLayout {
                Layout.fillWidth: true
                visible: !promptDialog.isReadyToPrompt
                Label {
                    Layout.fillWidth: true
                    text: qsTr("Please provide the AI URL, model and token first")
                    wrapMode: Text.WordWrap
                }
                QfButton {
                     text: qsTr("Configure...")
                     onClicked: {
                         promptDialog.close()
                         optionDialog.open()
                     }
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    text: qsTr("Context variables")
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 5
                    QfButton {
                        text: qsTr("@me")
                        enabled: promptDialog.isReadyToPrompt
                        onClicked: textAreaPrompt.insert(textAreaPrompt.cursorPosition, "@me")
                    }
                    QfButton {
                        text: qsTr("@mapcenter")
                        enabled: promptDialog.isReadyToPrompt
                        onClicked: textAreaPrompt.insert(textAreaPrompt.cursorPosition, " @mapcenter")
                    }
                    QfButton {
                        text: qsTr("@mapextent")
                        enabled: promptDialog.isReadyToPrompt
                        onClicked: textAreaPrompt.insert(textAreaPrompt.cursorPosition, " @mapextent")
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    text: qsTr("Prompts")
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 5

                    QfButton {
                        text: qsTr("Generate random")
                        enabled: promptDialog.isReadyToPrompt
                        onClicked: {
                            const poi_types = ["restaurants", "museums", "parks", "historical sites", "shopping centers"];
                            const poi_type = poi_types[Math.floor(Math.random() * poi_types.length)];
                            const poi_relations = ["near @me", "around @mapcenter", "within @mapextent"];
                            const poi_relation = poi_relations[Math.floor(Math.random() * poi_relations.length)];
                            const prompt = `List interesting ${poi_type} ${poi_relation}.`;
                            textAreaPrompt.text = prompt;
                            textAreaPrompt.cursorPosition = textAreaPrompt.text.length;
                        }
                    }
                    QfButton {
                        text: qsTr("Reload last")
                        enabled: promptDialog.isReadyToPrompt
                        onClicked: {
                            textAreaPrompt.text = settings.last_prompt;
                            textAreaPrompt.cursorPosition = textAreaPrompt.text.length;
                        }
                    }
                }
            }

            TextArea {
                id: textAreaPrompt
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: promptDialog.isReadyToPrompt
                text: settings.last_prompt
            }
        }

        onAccepted: {
            if (promptDialog.isReadyToPrompt ) {
              settings.last_prompt = textAreaPrompt.text;
              askaiLocatorFilter.locatorBridge.requestSearch("AAI " + textAreaPrompt.text);
           }
        }

        Component.onCompleted: {
            textAreaPrompt.focus = true;
            promptDialog.standardButton(Dialog.Ok).text = qsTr("Ask AI!");
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
                text: qsTr("API Provider")
            }
            ComboBox {
                id: comboBoxApiUrl
                Layout.fillWidth: true
                model: CONFIG.apis.map(api => api.name)
                currentIndex: CONFIG.apis.findIndex(api => api.url === settings.api_url)

                onActivated: {
                    comboBoxApiModel.currentIndex = 0;
                }
            }

            Label {
              id: labelApiModel
              text: qsTr("API Model")
            }
            ComboBox {
              id: comboBoxApiModel
              Layout.fillWidth: true
              model: CONFIG.apis[comboBoxApiUrl.currentIndex]["models"]
              currentIndex: CONFIG.apis[comboBoxApiUrl.currentIndex]["models"].indexOf(settings.api_model)
            }

            Label {
                id: labelApiKey
                Layout.fillWidth: true
                text: qsTr("API Key")
            }
            TextField {
                id: textFieldApiKey
                Layout.fillWidth: true
                text: settings.api_key
            }
            Label {
                id: labelApiKeyHelp
                Layout.fillWidth: true
                text: qsTr("%1Click here to sign up for a key%2").arg("<a href=\"" + (CONFIG.apis[comboBoxApiUrl.currentIndex]["key_url"] ?? "") + "\">").arg("</a>")
                wrapMode: Text.WordWrap
                visible: CONFIG.apis[comboBoxApiUrl.currentIndex]["key_url"] !== undefined
                onLinkActivated: (link) => { Qt.openUrlExternally(link); }
            }
        }

        onAccepted: {
            settings.api_url = CONFIG.apis[comboBoxApiUrl.currentIndex]["url"];
            settings.api_model = comboBoxApiModel.currentText;
            settings.api_key = textFieldApiKey.text;
            mainWindow.displayToast(qsTr("Settings stored"));
        }
    }
}
