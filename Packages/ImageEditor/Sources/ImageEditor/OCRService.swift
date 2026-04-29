import Foundation
import CoreGraphics
import Vision

public struct RecognizedTextBlock: Identifiable, Sendable {
    public let id = UUID()
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect

    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

public actor OCRService {
    public init() {}

    public func recognizeText(in image: CGImage, languages: [String] = ["zh-Hans", "en-US"]) async throws -> [RecognizedTextBlock] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks = observations.compactMap { observation -> RecognizedTextBlock? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return RecognizedTextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func recognizeFullText(in image: CGImage, languages: [String] = ["zh-Hans", "en-US"]) async throws -> String {
        let blocks = try await recognizeText(in: image, languages: languages)
        return blocks.map(\.text).joined(separator: "\n")
    }
}
