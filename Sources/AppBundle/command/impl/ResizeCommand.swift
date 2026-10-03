import AppKit
import Common

struct ResizeCommand: Command {
    let args: ResizeCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }

        if let window = target.windowOrNil,
           args.dimension.val == .smart || args.dimension.val == .width,
           let workspace = window.nodeWorkspace,
           workspace.rootTilingContainer.hasSingleLeafWindowRecursive,
           workspace.rootTilingContainer.anyLeafWindowRecursive === window
        {
            let monitor = workspace.workspaceMonitor
            let rect = monitor.visibleRectPaddedByOuterGaps
            if let baseWidth = config.singleWindowWidth(
                monitorWidth: monitor.width,
                availableWidth: rect.width,
                height: rect.height - 1
            ) {
                let currentWidth = window.singleWindowWidth(base: baseWidth, available: rect.width)
                let requestedWidth: CGFloat = switch args.units.val {
                    case .set(let unit): CGFloat(unit)
                    case .add(let unit): currentWidth + CGFloat(unit)
                    case .subtract(let unit): currentWidth - CGFloat(unit)
                }
                let newWidth = min(rect.width, max(min(200, rect.width), requestedWidth))
                window.singleWindowWidthAdjustment = newWidth - baseWidth
                return .succ
            }
        }

        let candidates = target.windowOrNil?.parentsWithSelf
            .filter { ($0.parent as? TilingContainer)?.layout == .tiles }
            ?? []

        let orientation: Orientation?
        let parent: TilingContainer?
        let node: TreeNode?
        switch args.dimension.val {
            case .width:
                orientation = .h
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
                parent = node?.parent as? TilingContainer
            case .height:
                orientation = .v
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
                parent = node?.parent as? TilingContainer
            case .smart:
                node = candidates.first
                parent = node?.parent as? TilingContainer
                orientation = parent?.orientation
            case .smartOpposite:
                orientation = (candidates.first?.parent as? TilingContainer)?.orientation.opposite
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
                parent = node?.parent as? TilingContainer
        }
        guard let parent else {
            return .fail(io.err("resize command doesn't support floating windows yet https://github.com/nikitabobko/AeroSpace/issues/9"))
        }
        guard let orientation else { return .fail }
        guard let node else { return .fail }
        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) - node.getWeight(orientation)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        guard let childDiff = diff.div(parent.children.count - 1) else { return .fail }
        parent.children.lazy
            .filter { $0 != node }
            .forEach { $0.setWeight(parent.orientation, $0.getWeight(parent.orientation) - childDiff) }

        node.setWeight(orientation, node.getWeight(orientation) + diff)
        return .succ
    }
}
