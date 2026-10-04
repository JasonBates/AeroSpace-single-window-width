import AppKit

/// A visual override only: the workspace tree and its tile weights stay intact.
@MainActor
final class FocusMode {
    static let shared = FocusMode()

    private(set) var workspaceName: String?
    private(set) var windowId: UInt32?
    private var originalFloatingFrame: Rect?

    var isActive: Bool { workspaceName != nil }

    func start(window: Window, workspace: Workspace) async {
        workspaceName = workspace.name
        windowId = window.windowId
        originalFloatingFrame = window.isFloating ? try? await window.getAxRect(.nonCancellable) : nil
    }

    func stop() {
        restoreFloatingWindow()
        workspaceName = nil
        windowId = nil
        originalFloatingFrame = nil
        FocusDimmer.shared.hide()
    }

    /// Called before every layout, so focus changes and closed windows cannot leave a stale cutout.
    func syncWithFocus() async {
        guard let workspaceName else { return }
        guard focus.workspace.name == workspaceName,
              let window = focus.windowOrNil,
              window.isFloating || window.parent is TilingContainer
        else {
            stop()
            return
        }
        if windowId != window.windowId {
            restoreFloatingWindow()
            windowId = window.windowId
            originalFloatingFrame = window.isFloating ? try? await window.getAxRect(.nonCancellable) : nil
        }
    }

    func frame(for window: Window, in workspace: Workspace) -> Rect? {
        guard workspaceName == workspace.name, windowId == window.windowId else { return nil }
        let monitor = workspace.workspaceMonitor
        let available = monitor.visibleRectPaddedByOuterGaps
        let baseWidth = config.singleWindowWidth(
            monitorWidth: monitor.width,
            availableWidth: available.width,
            height: available.height - 1
        ) ?? available.width * 0.66
        let width = window.singleWindowWidth(base: baseWidth, available: available.width)
        return Rect(
            topLeftX: available.topLeftX + (available.width - width) / 2,
            topLeftY: available.topLeftY,
            width: width,
            height: available.height - 1,
        )
    }

    func refreshBackdrop() {
        guard let windowId,
              let window = Window.get(byId: windowId),
              let workspace = window.nodeWorkspace,
              let frame = frame(for: window, in: workspace)
        else {
            FocusDimmer.shared.hide()
            return
        }
        FocusDimmer.shared.show(around: frame)
    }

    private func restoreFloatingWindow() {
        guard let windowId,
              let originalFloatingFrame,
              let window = Window.get(byId: windowId),
              window.isFloating,
              window.nodeWorkspace?.name == workspaceName
        else { return }
        window.setAxFrame(originalFloatingFrame.topLeftCorner, originalFloatingFrame.size)
    }
}
