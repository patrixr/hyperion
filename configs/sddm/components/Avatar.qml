import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Qt.labs.folderlistmodel

Rectangle {
    id: avatar
    property string shape: Config.avatarShape
    property string source: ""
    property string username: ""
    property bool active: false
    
    // JavaScript function to read file synchronously
    // Using Qt.include to load and execute JavaScript that reads the file
    function readTextFile(filePath) {
        var request = new XMLHttpRequest();
        request.open("GET", filePath, false); // Synchronous
        request.send(null);
        return request.responseText;
    }
    
    // Compute the actual avatar source.
    // Resolution order:
    //   1. avatarImage from ~/.config/noctalia/settings.json → general.avatarImage  (explicit user preference)
    //   2. SDDM-provided icon (if it isn't the generic user-default placeholder)
    //   3. ~/.face as a last resort
    property string actualSource: {
        var user = username !== "" ? username : (sddm.currentUser || "");

        // 1. Read avatar path from noctalia settings (general.avatarImage) — highest priority
        if (user !== "") {
            var settingsPath = "file:///home/" + user + "/.config/noctalia/settings.json";
            try {
                var jsonText = readTextFile(settingsPath);
                if (jsonText && jsonText !== "") {
                    var settings = JSON.parse(jsonText);
                    var avatarPath = settings && settings.general && settings.general.avatarImage;
                    if (avatarPath && avatarPath !== "") {
                        var url = avatarPath.startsWith("file://") ? avatarPath : "file://" + avatarPath;
                        console.log("Avatar: using noctalia avatar for " + user + ": " + url);
                        return url;
                    }
                }
            } catch (e) {
                console.log("Avatar: could not read noctalia settings for " + user + ": " + e);
            }
        }

        // 2. Use whatever SDDM resolved, unless it is the generic placeholder
        if (source && source !== "" && source.indexOf("user-default") === -1) {
            console.log("Avatar: falling back to SDDM-provided icon: " + source);
            return source;
        }

        // 3. Last resort: ~/.face
        if (user !== "") {
            console.log("Avatar: falling back to ~/.face for " + user);
            return "file:///home/" + user + "/.face";
        }

        return source;
    }
    property int squareRadius: (shape == "circle") ? this.width : (Config.avatarBorderRadius === 0 ? 1 : Config.avatarBorderRadius * Config.generalScale) // min: 1
    property bool drawStroke: (active && Config.avatarActiveBorderSize > 0) || (!active && Config.avatarInactiveBorderSize > 0)
    property color strokeColor: active ? Config.avatarActiveBorderColor : Config.avatarInactiveBorderColor
    property int strokeSize: active ? (Config.avatarActiveBorderSize * Config.generalScale) : (Config.avatarInactiveBorderSize * Config.generalScale)
    property string tooltipText: ""
    property bool showTooltip: false

    signal clicked
    signal clickedOutside

    radius: squareRadius
    color: "transparent"
    antialiasing: true

    // Background
    Rectangle {
        anchors.fill: parent
        radius: avatar.squareRadius
        color: Config.passwordInputBackgroundColor
        opacity: Config.passwordInputBackgroundOpacity
        visible: true
    }

    Image {
        id: faceImage
        source: parent.actualSource
        anchors.fill: parent
        mipmap: true
        antialiasing: true
        visible: false
        smooth: true

        fillMode: Image.PreserveAspectCrop
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter

        onStatusChanged: {
            if (status === Image.Error) {
                source = Config.getIcon("user-default");
                faceEffects.colorization = 1;
            }
        }

        // Border
        Rectangle {
            anchors.fill: parent
            radius: avatar.squareRadius
            color: "transparent"
            border.width: avatar.strokeSize
            border.color: avatar.strokeColor
            antialiasing: true
        }
    }
    MultiEffect {
        id: faceEffects
        anchors.fill: faceImage
        source: faceImage
        antialiasing: true
        maskEnabled: true
        maskSource: faceImageMask
        maskSpreadAtMin: 1.0
        maskThresholdMax: 1.0
        maskThresholdMin: 0.5
        colorization: 0
        colorizationColor: avatar.strokeColor === Config.passwordInputBackgroundColor && (1.0 - Config.passwordInputBackgroundOpacity < 0.3) ? Config.passwordInputContentColor : avatar.strokeColor
    }

    Item {
        id: faceImageMask

        height: this.width
        layer.enabled: true
        layer.smooth: true
        visible: false
        width: faceImage.width

        Rectangle {
            height: this.width
            radius: avatar.squareRadius
            width: faceImage.width
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor

        function isCursorInsideAvatar() {
            if (!mouseArea.containsMouse)
                return false;
            if (avatar.shape === "square")
                return true;

            // Ellipse center and radius
            var centerX = width / 2;
            var centerY = height / 2;
            var radiusX = centerX;
            var radiusY = centerY;

            // Distance from center
            var dx = (mouseArea.mouseX - centerX) / radiusX;
            var dy = (mouseArea.mouseY - centerY) / radiusY;

            // Check if pointer is inside the ellipse
            return (dx * dx + dy * dy) <= 1.0;
        }

        onReleased: function (mouse) {
            var isInside = isCursorInsideAvatar();
            if (isInside) {
                avatar.clicked();
            } else {
                avatar.clickedOutside();
            }
            mouse.accepted = isInside;
        }

        function updateHover() {
            if (isCursorInsideAvatar()) {
                cursorShape = Qt.PointingHandCursor;
            } else {
                cursorShape = Qt.ArrowCursor;
            }
        }

        onMouseXChanged: updateHover()
        onMouseYChanged: updateHover()

        ToolTip {
            id: toolTipControl
            parent: mouseArea
            enabled: Config.tooltipsEnable && !Config.tooltipsDisableUser
            property bool shouldShow: enabled && avatar.showTooltip || (enabled && mouseArea.isCursorInsideAvatar() && avatar.tooltipText !== "")
            visible: shouldShow
            delay: 300
            y: -height - 10
            x: (parent.width - width) / 2
            
            contentItem: Text {
                id: tooltipTextElement
                font.family: Config.tooltipsFontFamily
                font.pixelSize: Config.tooltipsFontSize * Config.generalScale
                text: avatar.tooltipText
                color: Config.tooltipsContentColor
            }
            background: Rectangle {
                implicitWidth: tooltipTextElement.implicitWidth + (toolTipControl.leftPadding + toolTipControl.rightPadding)
                implicitHeight: tooltipTextElement.implicitHeight + (toolTipControl.topPadding + toolTipControl.bottomPadding)
                color: Config.tooltipsBackgroundColor
                opacity: Config.tooltipsBackgroundOpacity
                border.width: 0
                radius: Config.tooltipsBorderRadius * Config.generalScale
            }
        }
    }
}
