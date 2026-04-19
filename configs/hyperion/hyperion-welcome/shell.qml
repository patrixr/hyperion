import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ShellRoot {
  property string currentShell: ""
  
  Process {
    id: shellChanger
    running: false
    
    onExited: function(code, status) {
      console.log("Process exited with code: " + code)
      console.log("Process stdout: " + stdout)
      console.log("Process stderr: " + stderr)
      if (code === 0) {
        console.log("Shell changed successfully")
      } else {
        console.log("Failed to change shell")
      }
    }
  }
  
  Component.onCompleted: {
    // Get current shell via nushell script
    shellDetector.running = true
  }
  
  Process {
    id: shellDetector
    command: ["nu", Qt.resolvedUrl("scripts/get-user-shell.nu").toString().replace("file://", ""), "patrick"]
    running: false
    
    stdout: SplitParser {
      onRead: function(data) {
        currentShell = data.trim()
        console.log("Detected current shell: " + currentShell)
      }
    }
  }
  Process {
    id: cleanup
    running: false
  }
  
  Process {
    id: userQuery
    property string username: "patrick"
  }
  
  function setShell(shell) {
    if (!userQuery.username) {
      // Get username from environment
      userQuery.username = "patrick"
    }
    console.log("Setting shell to: " + shell + " for user: " + userQuery.username)
    var scriptPath = Qt.resolvedUrl("scripts/change-shell.nu").toString().replace("file://", "")
    shellChanger.command = ["nu", scriptPath, shell, userQuery.username]
    shellChanger.running = true
    currentShell = shell
  }
  
  FloatingWindow {
    id: window
    implicitWidth: 700
    implicitHeight: 600
    visible: true
    
    screen: Quickshell.screens[0]
    
    color: "transparent"
    
    onVisibleChanged: {
      if (!visible) {
        Qt.quit()
      }
    }
    
    Rectangle {
      anchors.fill: parent
      color: "#1e1e2e"
      radius: 12
      border.color: "#89b4fa"
      border.width: 2
      
      Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20
        spacing: 20
        width: parent.width - 60
        
        Text {
          text: "Welcome to Hyperion"
          font.pixelSize: 32
          font.bold: true
          color: "#cdd6f4"
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          text: "EndeavourOS Community Edition"
          font.pixelSize: 14
          color: "#a6adc8"
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Rectangle {
          width: parent.width
          height: 1
          color: "#45475a"
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          text: "Hyperion is a modern Wayland desktop built around the Niri scrollable-tiling compositor.\nIt uses Nushell as the default shell for a powerful scripting experience."
          font.pixelSize: 13
          color: "#bac2de"
          wrapMode: Text.WordWrap
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          lineHeight: 1.3
        }
        
        Text {
          text: "<a href='https://github.com/patrixr/hyperion' style='color: #89b4fa; text-decoration: none;'>View on GitHub →</a>"
          font.pixelSize: 12
          color: "#89b4fa"
          textFormat: Text.RichText
          anchors.horizontalCenter: parent.horizontalCenter
          
          onLinkActivated: function(link) {
            Qt.openUrlExternally(link)
          }
          
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Qt.openUrlExternally("https://github.com/patrixr/hyperion")
          }
        }
        
        // Keybinds section
        Column {
          spacing: 8
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width
          
          Text {
            text: "Essential Keybinds (Mod = Super/Windows Key)"
            font.pixelSize: 14
            font.bold: true
            color: "#cdd6f4"
            anchors.horizontalCenter: parent.horizontalCenter
          }
          
          Grid {
            columns: 2
            columnSpacing: 30
            rowSpacing: 6
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Left column
            Text { text: "Mod+Return"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Open Terminal"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Space"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "App Launcher"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+O"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Toggle Overview"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Q"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Close Window"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Arrows"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Focus Window/Workspace"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Shift+Arrows"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Move Window"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+1-9"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Switch Workspace"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+R"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Resize Column Width"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+F"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Maximize Column"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Shift+F"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Fullscreen"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+V"; font.pixelSize: 11; font.bold: true; color: "#89b4fa" }
            Text { text: "Toggle Floating"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Left Click"; font.pixelSize: 11; font.bold: true; color: "#a6e3a1" }
            Text { text: "Move Window"; font.pixelSize: 11; color: "#bac2de" }
            
            Text { text: "Mod+Right Click"; font.pixelSize: 11; font.bold: true; color: "#a6e3a1" }
            Text { text: "Resize Window"; font.pixelSize: 11; color: "#bac2de" }
          }
        }
        
        Rectangle {
          width: parent.width
          height: 1
          color: "#45475a"
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Column {
          spacing: 12
          anchors.horizontalCenter: parent.horizontalCenter
          
          Text {
            text: "Choose your default shell:"
            font.pixelSize: 14
            font.bold: true
            color: "#cdd6f4"
            anchors.horizontalCenter: parent.horizontalCenter
          }
          
          Row {
            spacing: 12
            anchors.horizontalCenter: parent.horizontalCenter
            
            Button {
              text: "Nushell"
              onClicked: setShell("nu")
              
              background: Rectangle {
                color: {
                  if (currentShell === "nu") {
                    return parent.pressed ? "#a6e3a1" : "#a6e3a1"
                  } else {
                    return parent.pressed ? "#74c7ec" : "#89b4fa"
                  }
                }
                radius: 6
                implicitWidth: 100
                implicitHeight: 35
                border.color: currentShell === "nu" ? "#cdd6f4" : "transparent"
                border.width: currentShell === "nu" ? 2 : 0
              }
              
              contentItem: Text {
                text: parent.text
                font.pixelSize: 12
                font.bold: true
                color: "#1e1e2e"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }
            
            Button {
              text: "Bash"
              onClicked: setShell("bash")
              
              background: Rectangle {
                color: {
                  if (currentShell === "bash") {
                    return parent.pressed ? "#a6e3a1" : "#a6e3a1"
                  } else {
                    return parent.pressed ? "#74c7ec" : "#89b4fa"
                  }
                }
                radius: 6
                implicitWidth: 80
                implicitHeight: 35
                border.color: currentShell === "bash" ? "#cdd6f4" : "transparent"
                border.width: currentShell === "bash" ? 2 : 0
              }
              
              contentItem: Text {
                text: parent.text
                font.pixelSize: 12
                font.bold: true
                color: "#1e1e2e"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }
            
            Button {
              text: "Zsh"
              onClicked: setShell("zsh")
              
              background: Rectangle {
                color: {
                  if (currentShell === "zsh") {
                    return parent.pressed ? "#a6e3a1" : "#a6e3a1"
                  } else {
                    return parent.pressed ? "#74c7ec" : "#89b4fa"
                  }
                }
                radius: 6
                implicitWidth: 80
                implicitHeight: 35
                border.color: currentShell === "zsh" ? "#cdd6f4" : "transparent"
                border.width: currentShell === "zsh" ? 2 : 0
              }
              
              contentItem: Text {
                text: parent.text
                font.pixelSize: 12
                font.bold: true
                color: "#1e1e2e"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }
            }
          }
        }
      }
    }
  }
}
