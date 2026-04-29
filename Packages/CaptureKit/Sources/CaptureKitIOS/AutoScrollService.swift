#if os(iOS)
import Foundation
import UIKit

public actor AutoScrollService {
    private var isScrolling = false
    private let scrollDelay: TimeInterval = 0.2
    private let scrollFraction: CGFloat = 0.85

    public init() {}

    public func startAutoScroll(in scrollView: UIScrollView) async {
        guard !self.isScrolling else { return }
        self.isScrolling = true

        let metrics = await MainActor.run {
            (scrollView.bounds.height, scrollView.contentSize.height, scrollView.contentOffset.y)
        }

        let viewportHeight = metrics.0
        let contentHeight = metrics.1
        let maxOffsetY = contentHeight - viewportHeight
        var currentOffset = metrics.2

        while self.isScrolling, currentOffset < maxOffsetY {
            let nextOffset = min(currentOffset + viewportHeight * self.scrollFraction, maxOffsetY)

            await MainActor.run {
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut) {
                    scrollView.setContentOffset(CGPoint(x: 0, y: nextOffset), animated: false)
                }
            }

            try? await Task.sleep(for: .milliseconds(Int(self.scrollDelay * 1000) + 400))

            currentOffset = nextOffset

            if Task.isCancelled {
                break
            }
        }

        self.isScrolling = false
    }

    public func stopAutoScroll() {
        self.isScrolling = false
    }

    public var isActive: Bool {
        self.isScrolling
    }
}
#endif
