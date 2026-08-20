import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
  id: root
  moduleName: "nwarwick.omambience"

  property int activeCount: 0
  property int availableCount: 0
  readonly property int maximumVolume: 100
  property string statusText: "♫"
  property var sounds: []
  property var actionQueue: []

  readonly property string statusCommand: localPath(Qt.resolvedUrl("bin/omambience-status"))
  readonly property string toggleCommand: localPath(Qt.resolvedUrl("bin/omambience-toggle"))
  readonly property string volumeCommand: localPath(Qt.resolvedUrl("bin/omambience-volume"))
  readonly property string stopCommand: localPath(Qt.resolvedUrl("bin/omambience-stop-all"))

  function localPath(url) {
    return decodeURIComponent(String(url).replace(/^file:\/\//, ""))
  }

  function validSound(sound) {
    var value = String(sound || "")
    return /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(value) && value.indexOf("..") === -1
  }

  function validVolumeChange(change) {
    return /^[+-]?[0-9]{1,3}$/.test(String(change || ""))
  }

  function updateStatus(line) {
    try {
      var status = JSON.parse(String(line || ""))
      activeCount = Number(status.active || 0)
      availableCount = Number(status.available || 0)
      statusText = String(status.text || "♫")
      sounds = Array.isArray(status.sounds) ? status.sounds : []
    } catch (error) {
      console.warn("Omambience: invalid status response: " + error)
    }
  }

  function enqueue(command) {
    actionQueue = actionQueue.concat([command])
    runNextAction()
  }

  function patchSound(name, values) {
    var next = []
    var found = false
    var playing = 0
    for (var i = 0; i < sounds.length; i++) {
      var source = sounds[i]
      var copy = {}
      for (var key in source) copy[key] = source[key]
      if (String(copy.name) === String(name)) {
        for (var valueKey in values) copy[valueKey] = values[valueKey]
        found = true
      }
      if (copy.playing === true) playing++
      next.push(copy)
    }
    if (!found) return false
    sounds = next
    activeCount = playing
    statusText = playing > 1 ? "♫ " + playing : "♫"
    return true
  }

  function soundByName(name) {
    for (var i = 0; i < sounds.length; i++)
      if (String(sounds[i].name) === String(name)) return sounds[i]
    return null
  }

  function runNextAction() {
    if (actionProcess.running || actionQueue.length === 0) return
    var pending = actionQueue.slice()
    actionProcess.command = pending.shift()
    actionQueue = pending
    actionProcess.running = true
  }

  function toggleSound(sound) {
    if (!validSound(sound)) return "invalid sound"
    var current = soundByName(sound)
    if (current) patchSound(sound, { playing: current.playing !== true })
    enqueue([toggleCommand, String(sound)])
    return "ok"
  }

  function changeVolume(sound, change) {
    if (!validSound(sound) || !validVolumeChange(change)) return "invalid arguments"
    var current = soundByName(sound)
    if (current) {
      var raw = String(change)
      var volume = Number(current.volume || 0)
      if (raw.charAt(0) === "+") volume += Number(raw.slice(1))
      else if (raw.charAt(0) === "-") volume -= Number(raw.slice(1))
      else volume = Number(raw)
      patchSound(sound, { volume: Math.max(0, Math.min(maximumVolume, Math.round(volume))) })
    }
    enqueue([volumeCommand, String(sound), String(change)])
    return "ok"
  }

  function stopAllSounds() {
    for (var i = 0; i < sounds.length; i++) patchSound(sounds[i].name, { playing: false })
    enqueue([stopCommand])
    return "ok"
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  readonly property real openPanelIndicatorWidth: button.labelWidth
  readonly property real openPanelIndicatorHeight: Math.max(10, button.labelWidth)

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  visible: setting("alwaysShow", true) === true || activeCount > 0
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: statusProcess.running = true
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Process {
    id: statusProcess
    command: [root.statusCommand, "--watch"]
    stdout: SplitParser {
      onRead: function(line) { root.updateStatus(line) }
    }
    onExited: statusRestartTimer.restart()
  }

  Timer {
    id: statusRestartTimer
    interval: 1000
    repeat: false
    onTriggered: if (!statusProcess.running) statusProcess.running = true
  }

  Process {
    id: actionProcess
    onExited: root.runNextAction()
  }

  IpcHandler {
    target: root.moduleName

    function toggle(sound: string): string { return root.toggleSound(sound) }
    function volume(sound: string, change: string): string { return root.changeVolume(sound, change) }
    function stopAll(): string { return root.stopAllSounds() }
    function open(): string { root.open(); return "ok" }
    function close(): string { root.close(); return "ok" }
    function show(): string { root.open(); return "ok" }
    function hide(): string { root.close(); return "ok" }
    function togglePanel(): string { root.togglePanel(); return "ok" }
    function status(): string {
      return JSON.stringify({ active: root.activeCount, available: root.availableCount })
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.statusText
    active: root.activeCount > 0
    useActiveColor: false
    dimmed: root.activeCount === 0
    tooltipText: ""
    horizontalMargin: 8.5
    onPressed: function(button) {
      if (button === Qt.RightButton) root.stopAllSounds()
      else if (button === Qt.LeftButton) root.togglePanel()
    }
  }
}
