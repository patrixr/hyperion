import QtQuick
import QtQuick.Controls
import Quickshell

ShellRoot {
  FloatingWindow {
    id: window
    implicitWidth: 400
    implicitHeight: 200
    visible: true
    
    screen: Quickshell.screens[0]
    
    color: "transparent"
    
    Rectangle {
      anchors.fill: parent
      color: "#1e1e2e"
      radius: 12
      border.color: "#89b4fa"
      border.width: 2
      
      Column {
        anchors.centerIn: parent
        spacing: 20
        
        Text {
          text: "Hyperion"
          font.pixelSize: 48
          font.bold: true
          color: "#cdd6f4"
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
          text: "EndeavourOS Community Edition"
          font.pixelSize: 16
          color: "#a6adc8"
          anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Button {
          text: "Close"
          anchors.horizontalCenter: parent.horizontalCenter
          onClicked: Qt.quit()
          
          background: Rectangle {
            color: parent.pressed ? "#74c7ec" : "#89b4fa"
            radius: 6
            implicitWidth: 100
            implicitHeight: 35
          }
          
          contentItem: Text {
            text: parent.text
            font.pixelSize: 14
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
