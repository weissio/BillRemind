import UIKit
import Vision
import PDFKit
import CoreImage
import ImageIO

protocol OCRServicing {
    func recognizeText(from image: UIImage) async throws -> OCRExtractionResult
    func extractText(fromPDFAt url: URL) async throws -> OCRExtractionResult
}

struct OCRService: OCRServicing {
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func recognizeText(from image: UIImage) async throws -> OCRExtractionResult {
        guard let baseCGImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        let orientation = cgImageOrientation(for: image.imageOrientation)

        var variants: [(name: String, image: CGImage)] = [("Original", baseCGImage)]
        // Enhanced variants (contrast/brightness)
        if let enhanced = makeEnhancedOCRImage(from: baseCGImage, strong: false) {
            variants.append(("Enhanced", enhanced))
        }
        if let strong = makeEnhancedOCRImage(from: baseCGImage, strong: true) {
            variants.append(("HighContrast", strong))
        }
        // Denoised variant (optional noise reduction)
        if let denoised = makeEnhancedOCRImage(from: baseCGImage, strong: false, applyDenoise: true) {
            variants.append(("Denoised", denoised))
        }
        // Binarized variant (thresholded image)
        if let binarized = makeEnhancedOCRImage(from: baseCGImage, strong: false, makeBinarized: true) {
            variants.append(("Binarized", binarized))
        }

        var best: OCRCandidate?
        var lastError: Error?
        var attempted: [OCRCandidate] = []

        await withTaskGroup(of: (OCRCandidate?, OCRCandidate?).self) { group in
            for variant in variants {
                group.addTask {
                    do {
                        let corrected = try await self.recognizeText(
                            from: variant.image,
                            orientation: orientation,
                            variantName: "\(variant.name)-corrected",
                            usesLanguageCorrection: true
                        )
                        let raw = try await self.recognizeText(
                            from: variant.image,
                            orientation: orientation,
                            variantName: "\(variant.name)-raw",
                            usesLanguageCorrection: false
                        )
                        return (corrected, raw)
                    } catch {
                        lastError = error
                        return (nil, nil)
                    }
                }
            }
            for await result in group {
                if let corrected = result.0 {
                    attempted.append(corrected)
                    if best == nil || corrected.score > best!.score { best = corrected }
                }
                if let raw = result.1 {
                    attempted.append(raw)
                    if best == nil || raw.score > best!.score { best = raw }
                }
            }
        }

        if let best {
            var finalText = best.text
            let hasIbanInBest = hasIBANSignal(in: best.text)
            if !hasIbanInBest,
               let ibanCandidate = attempted
                .filter({ hasIBANSignal(in: $0.text) })
                .max(by: { ibanSignalScore($0.text) < ibanSignalScore($1.text) }),
               ibanCandidate.variantName != best.variantName {
                let merged = mergeOCRTexts(primary: best.text, secondary: ibanCandidate.text)
                if pageSignalScore(merged) >= pageSignalScore(best.text) {
                    finalText = merged
                }
            }

            if hasReceiptSignal(in: finalText),
               let sourceImage = sourceImage(for: best.variantName, variants: variants),
               let receiptRescue = try await supplementalReceiptAmountText(from: sourceImage, orientation: orientation),
               !receiptRescue.isEmpty {
                let merged = mergeOCRTexts(primary: finalText, secondary: receiptRescue)
                if receiptAmountSignalScore(merged) > receiptAmountSignalScore(finalText) {
                    finalText = merged
                }
            }

            let ranked = attempted.sorted { $0.score > $1.score }
            let topDebug = ranked.prefix(3).map {
                "\($0.variantName): score \(String(format: "%.2f", $0.score)), conf \(String(format: "%.2f", $0.meanConfidence)), lines \($0.lineCount)"
            }.joined(separator: " | ")
            let summary = "OCR gewählt: \(best.variantName) (score \(String(format: "%.2f", best.score)))" + (topDebug.isEmpty ? "" : "\n\(topDebug)")
            return OCRExtractionResult(text: finalText, debugSummary: summary)
        }
        throw lastError ?? OCRError.invalidImage
    }

    func extractText(fromPDFAt url: URL) async throws -> OCRExtractionResult {
        guard let document = PDFDocument(url: url) else {
            throw OCRError.invalidPDF
        }

        var chunks: [String] = []
        var hasDigitalText = false
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !text.isEmpty {
                hasDigitalText = true
                chunks.append(text)
            }
        }

        // For image-based PDFs, fall back to OCR on rendered page images.
        if !hasDigitalText {
            var debugLines: [String] = []
            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex),
                      let baseImage = renderImage(for: page, maxSide: 2600) else { continue }
                var ocr = try await recognizeText(from: baseImage)
                var trimmed = ocr.text.trimmingCharacters(in: .whitespacesAndNewlines)
                var rescueSourceImage = baseImage

                // Retry with larger render target when OCR is empty or too weak for invoice parsing.
                if isWeakPageOCR(trimmed), let highResImage = renderImage(for: page, maxSide: 3800) {
                    let retry = try await recognizeText(from: highResImage)
                    let retryTrimmed = retry.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if pageSignalScore(retryTrimmed) > pageSignalScore(trimmed) {
                        ocr = retry
                        trimmed = retryTrimmed
                        rescueSourceImage = highResImage
                    }
                }
                if isWeakPageOCR(trimmed), let ultraResImage = renderImage(for: page, maxSide: 4600) {
                    let retry = try await recognizeText(from: ultraResImage)
                    let retryTrimmed = retry.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if pageSignalScore(retryTrimmed) > pageSignalScore(trimmed) {
                        ocr = retry
                        trimmed = retryTrimmed
                        rescueSourceImage = ultraResImage
                    }
                }

                // Region rescue: header/footer crops often contain metadata blocks (invoice number/date/IBAN).
                // Use a larger render target for metadata OCR even when page OCR is otherwise strong.
                let metadataSourceImage = renderImage(for: page, maxSide: 5600) ?? rescueSourceImage
                if let rescueText = try await supplementalMetadataText(from: metadataSourceImage),
                   !rescueText.isEmpty {
                    let merged = [trimmed, rescueText]
                        .filter { !$0.isEmpty }
                        .joined(separator: "\n")
                    if pageSignalScore(merged) > pageSignalScore(trimmed) {
                        trimmed = merged
                    }
                }

                if !trimmed.isEmpty {
                    chunks.append(trimmed)
                }
                if let debug = ocr.debugSummary {
                    debugLines.append("Seite \(pageIndex + 1): \(debug)")
                }
            }
            return OCRExtractionResult(text: chunks.joined(separator: "\n"), debugSummary: debugLines.joined(separator: "\n"))
        }

        return OCRExtractionResult(text: chunks.joined(separator: "\n"), debugSummary: "PDF enthält digitalen Text (kein Vision-OCR verwendet)")
    }

    private func renderImage(for page: PDFPage, maxSide: CGFloat) -> UIImage? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let scale = min(maxSide / max(bounds.width, bounds.height), 8.0)
        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        guard width > 0, height > 0 else { return nil }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            return nil
        }

        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.saveGState()
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()

        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func recognizeText(
        from cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        variantName: String,
        usesLanguageCorrection: Bool
    ) async throws -> OCRCandidate {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let topCandidates = observations.compactMap { $0.topCandidates(1).first }
                let lines = topCandidates.map(\.string)
                let text = lines.joined(separator: "\n")
                let meanConfidence = topCandidates.isEmpty ? 0 : topCandidates.map(\.confidence).reduce(0, +) / Float(topCandidates.count)
                let score = scoreOCR(text: text, meanConfidence: meanConfidence)
                continuation.resume(returning: OCRCandidate(
                    variantName: variantName,
                    text: text,
                    score: score,
                    meanConfidence: meanConfidence,
                    lineCount: lines.count
                ))
            }
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = usesLanguageCorrection

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func makeEnhancedOCRImage(from cgImage: CGImage, strong: Bool, applyDenoise: Bool = false, makeBinarized: Bool = false) -> CGImage? {
        let input = CIImage(cgImage: cgImage)
        var workingImage = input
        // Optional denoise step
        if applyDenoise, let denoise = CIFilter(name: "CINoiseReduction") {
            denoise.setValue(workingImage, forKey: kCIInputImageKey)
            denoise.setValue(0.02, forKey: "inputNoiseLevel")
            denoise.setValue(0.40, forKey: "inputSharpness")
            if let out = denoise.outputImage { workingImage = out }
        }
        // Optional binarization step (simple threshold)
        if makeBinarized {
            // Convert to grayscale first
            if let gray = CIFilter(name: "CIColorControls") {
                gray.setValue(workingImage, forKey: kCIInputImageKey)
                gray.setValue(0.0, forKey: kCIInputSaturationKey)
                if let grayOut = gray.outputImage { workingImage = grayOut }
            }
            // Apply a harsh contrast to approximate binary image
            if let contrast = CIFilter(name: "CIColorMatrix") {
                contrast.setValue(workingImage, forKey: kCIInputImageKey)
                // Increase contrast dramatically
                contrast.setValue(CIVector(x: 10, y: 0, z: 0, w: 0), forKey: "inputRVector")
                contrast.setValue(CIVector(x: 0, y: 10, z: 0, w: 0), forKey: "inputGVector")
                contrast.setValue(CIVector(x: 0, y: 0, z: 10, w: 0), forKey: "inputBVector")
                contrast.setValue(CIVector(x: -5, y: -5, z: -5, w: 1), forKey: "inputBiasVector")
                if let binOut = contrast.outputImage { workingImage = binOut }
            }
        }
        // Continue with original contrast/brightness/sharpen pipeline
        guard let colorControls = CIFilter(name: "CIColorControls") else { return nil }
        colorControls.setValue(workingImage, forKey: kCIInputImageKey)
        colorControls.setValue(0.0, forKey: kCIInputSaturationKey)
        colorControls.setValue(strong ? 1.85 : 1.35, forKey: kCIInputContrastKey)
        colorControls.setValue(strong ? 0.03 : 0.01, forKey: kCIInputBrightnessKey)
        guard let colorAdjusted = colorControls.outputImage else { return nil }

        guard let sharpen = CIFilter(name: "CISharpenLuminance") else {
            return ciContext.createCGImage(colorAdjusted, from: colorAdjusted.extent)
        }
        sharpen.setValue(colorAdjusted, forKey: kCIInputImageKey)
        sharpen.setValue(strong ? 1.2 : 0.6, forKey: kCIInputSharpnessKey)
        guard let output = sharpen.outputImage else {
            return ciContext.createCGImage(colorAdjusted, from: colorAdjusted.extent)
        }
        return ciContext.createCGImage(output, from: output.extent)
    }

    private func scoreOCR(text: String, meanConfidence: Float) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let lower = trimmed.lowercased()
        let chars = Double(trimmed.count)
        let lines = Double(trimmed.split(separator: "\n").count)
        let keywordHits = ["rechnung", "betrag", "gesamt", "eur", "€", "iban", "rechnungsnummer"]
            .reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let dateHits = lower.matches(for: #"\b\d{2}\.\d{2}\.\d{2,4}\b|\b\d{4}-\d{2}-\d{2}\b"#).count
        let amountHits = lower.matches(for: #"\d{1,3}(?:[\.\s]\d{3})*(?:[\.,]\d{2})|\d+[\.,]\d{2}"#).count
        let invoiceNoHits = lower.matches(for: #"\b(?:re|rg|inv)[-\s]?\d{4,}\b"#).count

        return chars * 0.004
            + lines * 0.15
            + Double(keywordHits) * 1.8
            + Double(dateHits) * 0.8
            + Double(amountHits) * 0.5
            + Double(invoiceNoHits) * 1.3
            + Double(meanConfidence) * 6.0
    }

    private func hasIBANSignal(in text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("iban") || lower.contains("bic") || lower.contains("account") || lower.contains("konto") {
            return true
        }
        return lower.range(of: #"\bd[ei1l]\s*[:\-]?\s*\d{2}"#, options: .regularExpression) != nil
    }

    private func ibanSignalScore(_ text: String) -> Double {
        let lower = text.lowercased()
        let keywordHits = ["iban", "bic", "account", "konto", "payment", "zahlung"].reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let deHits = lower.matches(for: #"\bd[ei1l][\s:/-]*\d{2}"#).count
        let lineHits = lower.matches(for: #"(?i)\b(?:iban|account|pay(?:ment)?|zan|tan|ban|an)\b.*(?:bic|d[ei1l])"#).count
        return Double(keywordHits) * 2.5 + Double(deHits) * 1.8 + Double(lineHits) * 3.0
    }

    private func mergeOCRTexts(primary: String, secondary: String) -> String {
        var seen = Set<String>()
        var merged: [String] = []
        let primaryLines = primary.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let secondaryLines = secondary.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        for line in primaryLines + secondaryLines {
            let key = line.lowercased()
            if seen.insert(key).inserted {
                merged.append(line)
            }
        }
        return merged.joined(separator: "\n")
    }

    private func sourceImage(for variantName: String, variants: [(name: String, image: CGImage)]) -> CGImage? {
        guard let prefix = variantName.split(separator: "-").first else { return nil }
        return variants.first(where: { $0.name == String(prefix) })?.image
    }

    private func isWeakPageOCR(_ text: String) -> Bool {
        pageSignalScore(text) < 7.0
    }

    private func pageSignalScore(_ text: String) -> Double {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let lower = trimmed.lowercased()
        let chars = Double(trimmed.count)
        let keywordHits = ["rechnung", "invoice", "iban", "rechnungsnummer", "invoice number", "invoice date"]
            .reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let numberHits = lower.matches(for: #"\b(?:re|rg|inv)[-\s]?\d{4,}\b"#).count
        let dateHits = lower.matches(for: #"\b\d{1,2}\.\d{1,2}\.\d{2,4}\b|\b\d{4}-\d{2}-\d{2}\b"#).count
        return chars * 0.002 + Double(keywordHits) * 1.8 + Double(numberHits) * 1.6 + Double(dateHits) * 0.8
    }

    private func hasReceiptSignal(in text: String) -> Bool {
        let lower = text.lowercased()
        let markers = ["kassenbon", "beleg", "summe", "zahlart", "rückgeld", "rueckgeld", "bar gegeben", "ec-karte"]
        return markers.contains(where: { lower.contains($0) })
    }

    private func receiptAmountSignalScore(_ text: String) -> Double {
        let lower = text.lowercased()
        let amountHits = lower.matches(for: #"\d{1,3}(?:[\.\s]\d{3})*(?:[\.,]\d{2})|\d+[\.,]\d{2}"#).count
        let keywordHits = ["summe", "gesamt", "zu zahlen", "zahlbetrag", "bar gegeben", "rückgeld", "rueckgeld", "zahlart", "ec", "karte"]
            .reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        return Double(amountHits) * 1.0 + Double(keywordHits) * 2.0
    }

    private func supplementalMetadataText(from image: UIImage) async throws -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 200, height > 200 else { return nil }

        // Target common metadata zones across invoice templates.
        let zones: [CGRect] = [
            CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height) * 0.48), // top block
            CGRect(x: CGFloat(width) * 0.35, y: 0, width: CGFloat(width) * 0.65, height: CGFloat(height) * 0.55), // top-right metadata
            CGRect(x: 0, y: CGFloat(height) * 0.58, width: CGFloat(width), height: CGFloat(height) * 0.42), // bottom bank/footer block
            CGRect(x: CGFloat(width) * 0.45, y: CGFloat(height) * 0.60, width: CGFloat(width) * 0.55, height: CGFloat(height) * 0.35), // bottom-right bank lines
            CGRect(x: 0, y: CGFloat(height) * 0.78, width: CGFloat(width), height: CGFloat(height) * 0.22), // footer strip
            CGRect(x: CGFloat(width) * 0.38, y: CGFloat(height) * 0.42, width: CGFloat(width) * 0.62, height: CGFloat(height) * 0.40), // short-invoice right metadata window
            CGRect(x: 0, y: CGFloat(height) * 0.46, width: CGFloat(width), height: CGFloat(height) * 0.30) // middle strip for shifted bank block
        ]

        var snippets: [String] = []
        for zone in zones {
            let cropRect = zone.integral
            guard let crop = cgImage.cropping(to: cropRect) else { continue }
            let cropImage = UIImage(cgImage: crop)
            let ocr = try await recognizeText(from: cropImage)
            let text = ocr.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                snippets.append(text)
            }
        }
        if snippets.isEmpty { return nil }
        return snippets.joined(separator: "\n")
    }

    private func supplementalReceiptAmountText(
        from cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> String? {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 200, height > 200 else { return nil }

        let zones: [CGRect] = [
            CGRect(x: CGFloat(width) * 0.52, y: 0, width: CGFloat(width) * 0.48, height: CGFloat(height)), // right value column
            CGRect(x: 0, y: CGFloat(height) * 0.50, width: CGFloat(width), height: CGFloat(height) * 0.50), // lower totals/payment area
            CGRect(x: CGFloat(width) * 0.30, y: CGFloat(height) * 0.38, width: CGFloat(width) * 0.70, height: CGFloat(height) * 0.56) // mixed right-middle
        ]

        var snippets: [String] = []
        for zone in zones {
            let rect = zone.integral
            guard let crop = cgImage.cropping(to: rect) else { continue }
            let candidate = try await recognizeText(
                from: crop,
                orientation: orientation,
                variantName: "ReceiptRescue",
                usesLanguageCorrection: false
            )
            let text = candidate.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                snippets.append(text)
            }
        }
        if snippets.isEmpty { return nil }
        return snippets.joined(separator: "\n")
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

enum OCRError: Error {
    case invalidImage
    case invalidPDF
}

private struct OCRCandidate {
    let variantName: String
    let text: String
    let score: Double
    let meanConfidence: Float
    let lineCount: Int
}

struct OCRExtractionResult {
    let text: String
    let debugSummary: String?
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard count <= 500_000 else { return [] }
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(startIndex..<endIndex, in: self)
        return regex.matches(in: self, range: nsRange).compactMap { result in
            guard let range = Range(result.range, in: self) else { return nil }
            return String(self[range])
        }
    }
}
