import QtQuick
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property int refreshIntervalSec: 2
  property string networkInterface: "auto"

  property real cpuPercent: 0
  property real ramPercent: 0
  property real gpuPercent: 0
  property bool gpuAvailable: false
  property real uploadBytesPerSec: 0
  property real downloadBytesPerSec: 0
  property string activeInterface: ""
  property bool ready: false

  property real previousTimestampNs: 0
  property real previousCpuTotal: 0
  property real previousCpuIdle: 0
  property real previousRxBytes: 0
  property real previousTxBytes: 0
  property string previousInterface: ""

  readonly property string helperPath: String(Qt.resolvedUrl("bin/omarchy-hw-stats-snapshot"))
    .replace(/^file:\/\//, "")

  function clampedInterval() {
    return Math.max(1, Math.min(60, parseInt(refreshIntervalSec, 10) || 2))
  }

  function refresh() {
    if (snapshotProcess.running) return
    snapshotProcess.command = [root.helperPath, "--interface", root.networkInterface || "auto"]
    snapshotProcess.running = true
  }

  function applySnapshot(snapshot) {
    var timestamp = Number(snapshot.timestampNs || 0)
    var cpuTotal = Number(snapshot.cpuTotal || 0)
    var cpuIdle = Number(snapshot.cpuIdle || 0)
    var rx = Number(snapshot.rxBytes || 0)
    var tx = Number(snapshot.txBytes || 0)
    var iface = String(snapshot.interface || "")

    root.ramPercent = Math.max(0, Math.min(100, Number(snapshot.ramPercent || 0)))
    root.gpuAvailable = snapshot.gpuPercent !== null && snapshot.gpuPercent !== undefined
    if (root.gpuAvailable)
      root.gpuPercent = Math.max(0, Math.min(100, Number(snapshot.gpuPercent)))

    var cpuDelta = cpuTotal - root.previousCpuTotal
    var idleDelta = cpuIdle - root.previousCpuIdle
    if (root.previousCpuTotal > 0 && cpuDelta > 0 && idleDelta >= 0)
      root.cpuPercent = Math.max(0, Math.min(100, (cpuDelta - idleDelta) * 100 / cpuDelta))

    var elapsed = (timestamp - root.previousTimestampNs) / 1000000000
    var sameInterface = iface !== "" && iface === root.previousInterface
    if (root.previousTimestampNs > 0 && elapsed > 0 && sameInterface
        && rx >= root.previousRxBytes && tx >= root.previousTxBytes) {
      root.downloadBytesPerSec = (rx - root.previousRxBytes) / elapsed
      root.uploadBytesPerSec = (tx - root.previousTxBytes) / elapsed
    } else {
      root.downloadBytesPerSec = 0
      root.uploadBytesPerSec = 0
    }

    root.previousTimestampNs = timestamp
    root.previousCpuTotal = cpuTotal
    root.previousCpuIdle = cpuIdle
    root.previousRxBytes = rx
    root.previousTxBytes = tx
    root.previousInterface = iface
    root.activeInterface = iface
    root.ready = true
  }

  Process {
    id: snapshotProcess
    command: []
    stdout: StdioCollector { id: snapshotOutput; waitForEnd: true }
    stderr: StdioCollector { id: snapshotError; waitForEnd: true }

    onExited: function(exitCode) {
      if (exitCode !== 0) {
        console.warn("io.github.leomoon-studios.hw-stats: snapshot failed:", String(snapshotError.text || "").trim())
        return
      }
      try {
        root.applySnapshot(JSON.parse(snapshotOutput.text))
      } catch (error) {
        console.warn("io.github.leomoon-studios.hw-stats: invalid snapshot:", String(error))
      }
    }
  }

  Timer {
    interval: root.clampedInterval() * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
