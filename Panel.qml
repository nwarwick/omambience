import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "nwarwick.omambience"
  ipcTarget: "nwarwick.omambience"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function displayName(name) {
    var value = String(name || "")
    return value.length > 0 ? value.charAt(0).toUpperCase() + value.slice(1) : "Sound"
  }

  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(barIdentity, direction)
    return false
  }

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: popup.fittedContentWidth(Style.space(360))
    contentHeight: popup.fittedContentHeight(
      panelHeader.implicitHeight + headerSeparator.implicitHeight
        + soundsColumn.implicitHeight + Style.space(24),
      Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelLayout
        anchors.fill: parent
        spacing: Style.space(12)

        Item {
          id: panelHeader
          width: parent.width
          implicitHeight: stopAllButton.implicitHeight

          Button {
            id: stopAllButton
            anchors.right: parent.right
            text: root.hostWidget && root.hostWidget.activeCount > 0
              ? "Stop all"
              : "Stopped"
            bordered: true
            focusable: true
            enabled: !!root.hostWidget && root.hostWidget.activeCount > 0
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.hostWidget.stopAllSounds()
          }
        }

        PanelSeparator {
          id: headerSeparator
          foreground: root.foreground
        }

        Flickable {
          width: parent.width
          height: Math.max(0, panelLayout.height - panelHeader.implicitHeight
            - headerSeparator.implicitHeight - panelLayout.spacing * 2)
          contentWidth: width
          contentHeight: soundsColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height

          Column {
            id: soundsColumn
            width: parent.width
            spacing: Style.space(8)

            Repeater {
              model: root.hostWidget ? root.hostWidget.sounds : []

              SoundControl {
                required property var modelData
                width: soundsColumn.width
                soundData: modelData
              }
            }

            Text {
              visible: !root.hostWidget || root.hostWidget.availableCount === 0
              width: parent.width
              text: "No ambient sounds installed"
              color: Qt.darker(root.foreground, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }
          }
        }
      }
    }
  }

  component SoundControl: Column {
    id: soundControl

    required property var soundData
    readonly property string soundName: String(soundData && soundData.name || "")
    readonly property int soundVolume: Number(soundData && soundData.volume || 0)
    spacing: Style.space(2)

    Toggle {
      width: parent.width
      label: root.displayName(soundControl.soundName)
      description: soundControl.soundData && soundControl.soundData.playing === true ? "Playing" : "Stopped"
      checked: soundControl.soundData && soundControl.soundData.playing === true
      foreground: root.foreground
      fontFamily: root.fontFamily
      onClicked: if (root.hostWidget) root.hostWidget.toggleSound(soundControl.soundName)
    }

    Row {
      width: parent.width
      spacing: Style.space(10)

      PanelSlider {
        id: volumeSlider
        width: parent.width - volumeLabel.width - parent.spacing
        bar: root.bar
        minimum: 0
        maximum: root.hostWidget ? root.hostWidget.maximumVolume : 100
        step: 5
        integer: true
        value: soundControl.soundVolume
        onReleased: function(value) {
          if (root.hostWidget) root.hostWidget.changeVolume(soundControl.soundName, String(Math.round(value)))
        }
      }

      Text {
        id: volumeLabel
        width: Style.space(42)
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(volumeSlider.liveValue) + "%"
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
