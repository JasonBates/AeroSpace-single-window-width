import AppKit

/// A frame of `size` centred on `center`, shrunk and shifted as little as needed to fit inside `bounds`.
func floatingFrame(center: CGPoint, size: CGSize, within bounds: Rect) -> Rect {
    let width = min(size.width, bounds.width)
    let height = min(size.height, bounds.height)
    let x = (center.x - width / 2).clamped(bounds.topLeftX, bounds.topLeftX + bounds.width - width)
    let y = (center.y - height / 2).clamped(bounds.topLeftY, bounds.topLeftY + bounds.height - height)
    return Rect(topLeftX: x, topLeftY: y, width: width, height: height)
}

extension CGFloat {
    fileprivate func clamped(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat { Swift.max(lower, Swift.min(self, upper)) }
}
