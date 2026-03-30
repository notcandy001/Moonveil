function listApps() {
    var files = []
    var dir = "/usr/share/applications"
    var proc = Qt.createQmlObject('import QtQuick; Process {}', Qt.application)

    proc.program = "bash"
    proc.arguments = ["-c", "ls " + dir + "/*.desktop 2>/dev/null"]
    proc.start()
    proc.waitForFinished()

    var output = proc.readAllStandardOutput().trim().split("\n")

    for (var i = 0; i < output.length; i++) {
        if (output[i])
            files.push(output[i])
    }

    return files
}
