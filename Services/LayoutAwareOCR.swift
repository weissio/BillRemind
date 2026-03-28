import UIKit
import Vision

/// A single recognized text block with its spatial position on the page.
struct OCRTextBlock {
    let text: String
    let confidence: Float
    /// Normalized bounding box in Vision coordinates (origin bottom-left, 0…1).
    let boundingBox: CGRect

    /// Center Y in top-down page coordinates (0 = top, 1 = bottom).
    var centerY: CGFloat { 1.0 - boundingBox.midY }
    /// Center X in left-to-right coordinates (0 = left, 1 = right).
    var centerX: CGFloat { boundingBox.midX }
    /// Approximate height of the text block.
    var height: CGFloat { boundingBox.height }
}

/// Result of a layout-aware OCR pass that preserves spatial information.
struct LayoutAwareOCRResult {
    let blocks: [OCRTextBlock]
    let fullText: String

    /// Group blocks into rows based on vertical proximity.
    func rows(tolerance: CGFloat = 0.012) -> [[OCRTextBlock]] {
        guard !blocks.isEmpty else { return [] }
        let sorted = blocks.sorted { $0.centerY < $1.centerY }
        var rows: [[OCRTextBlock]] = [[sorted[0]]]

        for block in sorted.dropFirst() {
            if abs(block.centerY - rows[rows.count - 1][0].centerY) < tolerance {
                rows[rows.count - 1].append(block)
            } else {
                rows.append([block])
            }
        }
        // Sort each row left-to-right
        return rows.map { $0.sorted { $0.centerX < $1.centerX } }
    }
}

/// Performs Vision OCR while preserving bounding box positions for spatial parsing.
struct LayoutAwareOCRService {

    func recognizeWithLayout(from image: UIImage) async throws -> LayoutAwareOCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        let orientation = cgImageOrientation(for: image.imageOrientation)
        return try await recognizeWithLayout(from: cgImage, orientation: orientation)
    }

    func recognizeWithLayout(
        from cgImage: CGImage,
        orientation: CGImagePropertyOrientation = .up
    ) async throws -> LayoutAwareOCRResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                var blocks: [OCRTextBlock] = []
                for obs in observations {
                    guard let candidate = obs.topCandidates(1).first else { continue }
                    blocks.append(OCRTextBlock(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: obs.boundingBox
                    ))
                }
                let fullText = blocks
                    .sorted { $0.centerY < $1.centerY }
                    .map(\.text)
                    .joined(separator: "\n")
                continuation.resume(returning: LayoutAwareOCRResult(
                    blocks: blocks,
                    fullText: fullText
                ))
            }
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func cgImageOrientation(for orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
