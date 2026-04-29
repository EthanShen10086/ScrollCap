import Foundation
import CoreGraphics
import SharedModels

@MainActor
public protocol CaptureService: AnyObject, Sendable {
    var state: CaptureState { get }
    var currentPreview: CGImage? { get }
    var onStateChanged: ((CaptureState) -> Void)? { get set }
    var onPreviewUpdated: ((CGImage) -> Void)? { get set }

    func prepare() async throws
    func startCapture(region: CaptureRegion?) async throws
    func stopCapture() async throws -> Screenshot?
    func cancelCapture()
    func requestPermission() async -> Bool
}
