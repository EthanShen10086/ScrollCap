#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation
import OSLog
import SharedModels

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "live-activity")
    private var currentActivity: Activity<CaptureActivityAttributes>?

    private init() {}

    func startCapture() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            self.logger.info("Live Activities not enabled")
            return
        }

        let attributes = CaptureActivityAttributes()
        let initialState = CaptureActivityAttributes.ContentState(phase: .preparing)

        do {
            self.currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.logger.info("Live Activity started")
        } catch {
            self.logger.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    func update(
        frames: Int,
        elapsed: TimeInterval,
        estimatedHeight: CGFloat,
        phase: CaptureActivityAttributes.CapturePhase
    ) {
        let state = CaptureActivityAttributes.ContentState(
            capturedFrames: frames,
            elapsedSeconds: Int(elapsed),
            estimatedHeight: Int(estimatedHeight),
            phase: phase
        )

        Task {
            await self.currentActivity?.update(.init(state: state, staleDate: nil))
        }
    }

    func endCapture(frames: Int) {
        let finalState = CaptureActivityAttributes.ContentState(
            capturedFrames: frames,
            phase: .completed
        )

        Task {
            await self.currentActivity?.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now + 5)
            )
            self.currentActivity = nil
            self.logger.info("Live Activity ended")
        }
    }

    func endWithFailure() {
        let failState = CaptureActivityAttributes.ContentState(phase: .failed)
        Task {
            await self.currentActivity?.end(
                .init(state: failState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.currentActivity = nil
        }
    }
}
#endif
