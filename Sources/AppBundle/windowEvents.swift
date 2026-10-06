import Common

/// The workspace of every window as of the last check. Used to report window-moved events
@MainActor private var lastKnownWindowWorkspaces: [UInt32: String] = [:]

@MainActor func rememberWindowWorkspace(_ window: Window) {
    lastKnownWindowWorkspaces[window.windowId] = window.nodeWorkspace?.name
}

@MainActor func forgetWindowWorkspace(_ windowId: UInt32) {
    lastKnownWindowWorkspaces.removeValue(forKey: windowId)
}

// Should be called in refreshSession
@MainActor func checkWindowWorkspaceChanges() {
    for event in collectWindowMovedEvents() {
        broadcastEvent(event)
    }
}

/// Windows that are on a different workspace than at the previous check.
/// Windows outside any workspace (minimized, popups) are not tracked
@MainActor func collectWindowMovedEvents() -> [ServerEvent] {
    var current: [UInt32: String] = [:]
    var events: [ServerEvent] = []
    for workspace in Workspace.all {
        for window in workspace.allLeafWindowsRecursive {
            current[window.windowId] = workspace.name
            if let prevWorkspace = lastKnownWindowWorkspaces[window.windowId], prevWorkspace != workspace.name {
                events.append(.windowMoved(
                    windowId: window.windowId,
                    workspace: workspace.name,
                    prevWorkspace: prevWorkspace,
                    appBundleId: window.app.rawAppBundleId,
                    appName: window.app.name,
                ))
            }
        }
    }
    lastKnownWindowWorkspaces = current
    return events
}
