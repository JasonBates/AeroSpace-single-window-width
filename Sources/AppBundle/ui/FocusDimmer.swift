import AppKit
import Common

/// Nonactivating, click-through panels let the focused application keep keyboard and mouse input.
@MainActor
final class FocusDimmer {
    static let shared = FocusDimmer()

    private var panels: [FocusDimPanel] = []
    private var animationGeneration = 0

    func show(around windowRect: Rect) {
        guard !isUnitTest else { return }
        animationGeneration += 1
        let appKitRect = CGRect(
            x: windowRect.minX,
            y: mainMonitorInfo.height - windowRect.maxY,
            width: windowRect.width,
            height: windowRect.height,
        )
        let screens = NSScreen.screens
        while panels.count > screens.count {
            panels.removeLast().orderOut(nil)
        }
        for (index, screen) in screens.enumerated() {
            if index == panels.count { panels.append(FocusDimPanel()) }
            let panel = panels[index]
            panel.setFrame(screen.frame, display: true)
            let hole = appKitRect.offsetBy(dx: -screen.frame.minX, dy: -screen.frame.minY)
            panel.dimmingView.hole = hole.intersection(panel.dimmingView.bounds)
            let wasVisible = panel.isVisible
            if !wasVisible {
                panel.alphaValue = 0
            }
            panel.orderFrontRegardless()
            if !wasVisible || panel.alphaValue < 1 {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.18
                    panel.animator().alphaValue = 1
                }
            }
        }
    }

    func hide() {
        guard !isUnitTest else { return }
        animationGeneration += 1
        let generation = animationGeneration
        for panel in panels where panel.isVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self, weak panel] in
                Task.startUnstructured { @MainActor in
                    guard self?.animationGeneration == generation else { return }
                    panel?.orderOut(nil)
                }
            }
        }
    }
}

@MainActor
private final class FocusDimPanel: NSPanel {
    let dimmingView = FocusDimmingView()

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false,
        )
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        hasShadow = false
        isOpaque = false
        backgroundColor = .clear
        contentView = dimmingView
    }
}

@MainActor
private final class FocusDimmingView: NSView {
    var hole: CGRect = .null {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(rect: bounds)
        if !hole.isNull && !hole.isEmpty {
            path.appendRect(hole)
            path.windingRule = .evenOdd
        }
        NSColor.black.withAlphaComponent(0.78).setFill()
        path.fill()
    }
}
