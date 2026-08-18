import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.leomoon-studios.hw-stats"

  readonly property var stats: bar?.shell?.serviceFor("io.github.leomoon-studios.hw-stats")
  readonly property int configuredInterval: Math.max(1, Math.min(60,
    parseInt(String(setting("refreshIntervalSec", 2)), 10) || 2))
  readonly property string configuredInterface: String(setting("networkInterface", "auto") || "auto")
  readonly property real horizontalPadding: Style.spaceReal(8.75)

  function formatRate(value) {
    var bytes = Math.max(0, Number(value || 0))
    var units = ["B", "K", "M", "G", "T"]
    var index = 0
    while (bytes >= 1024 && index < units.length - 1) {
      bytes /= 1024
      index += 1
    }
    if (index === 0) return Math.round(bytes) + units[index]
    var rounded = Math.round(bytes * 10) / 10
    return (rounded % 1 === 0 ? rounded.toFixed(0) : rounded.toFixed(1)) + units[index]
  }

  function percent(value) {
    return Math.round(Math.max(0, Math.min(100, Number(value || 0)))) + "%"
  }

  function configureService() {
    if (!stats) return
    stats.refreshIntervalSec = configuredInterval
    stats.networkInterface = configuredInterface
  }

  onStatsChanged: configureService()
  onConfiguredIntervalChanged: configureService()
  onConfiguredInterfaceChanged: configureService()
  Component.onCompleted: configureService()

  // Match the horizontal breathing room used by Omarchy's text widgets.
  implicitWidth: metrics.implicitWidth + horizontalPadding * 2
  implicitHeight: barSize

  Row {
    id: metrics
    anchors.centerIn: parent
    spacing: Style.space(12)

    Text {
      text: " " + (root.stats && root.stats.ready ? root.percent(root.stats.cpuPercent) : "--%")
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      text: " " + (root.stats && root.stats.ready ? root.percent(root.stats.ramPercent) : "--%")
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      visible: root.stats && root.stats.gpuAvailable
      text: "󰢮 " + root.percent(root.stats ? root.stats.gpuPercent : 0)
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      text: " " + root.formatRate(root.stats ? root.stats.uploadBytesPerSec : 0)
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }

    Text {
      text: " " + root.formatRate(root.stats ? root.stats.downloadBytesPerSec : 0)
      color: root.bar.barForeground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.body
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: if (root.bar) root.bar.showTooltip(root,
      "Hardware stats" + (root.stats && root.stats.activeInterface
        ? " · Network: " + root.stats.activeInterface : ""))
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }
}
