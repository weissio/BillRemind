import XCTest
import PDFKit
import UIKit
@testable import BillRemind

/// Smoke-Test fuer den Foto-/Kamera-Pfad: rendert eine bekannte PDF zu UIImage
/// und schickt sie durch die volle 10-Varianten-Vision-OCR-Pipeline. Damit
/// fangen wir Regressionen ab, bei denen recognizeText(from: UIImage) leer
/// zurueckkommt oder crasht — z. B. wenn jemand spaeter den TaskGroup-Pfad
/// oder die CIFilter-Vorbearbeitung umstellt.
///
/// Anders als der Korpus-Test (PDFKit -> Text -> Parser) deckt dieser Test
/// den Vision-Pfad ab, der ausschliesslich beim echten Foto/Kamera-Scan
/// und bei Bild-PDFs ohne Text-Layer zum Einsatz kommt.
///
/// Hinweis Performance: Vision braucht je Bild mehrere Sekunden. Der Test
/// ist daher als ein einziger Smoke-Case angelegt, nicht als Korpus-Sweep.
final class OCRServiceTests: XCTestCase {

    func testRecognizesAnchorTextFromRenderedInvoiceImage() async throws {
        // Pfad zur Korpus-PDF relativ zur Test-Quelldatei. Funktioniert auf
        // Dev-Macs und auf CI, weil #file zur Compile-Zeit aufgeloest wird.
        let testFileURL = URL(fileURLWithPath: #file)
        let projectRoot = testFileURL
            .deletingLastPathComponent()    // BillRemindTests/
            .deletingLastPathComponent()    // Tests/
            .deletingLastPathComponent()    // project root
        let pdfURL = projectRoot
            .appendingPathComponent("Testdaten/OCR-Korpus/rechnung/01_stadtwerke_rechnung.pdf")

        guard let image = renderFirstPageToUIImage(at: pdfURL, maxSide: 1800) else {
            XCTFail("Konnte PDF nicht zu UIImage rendern: \(pdfURL.path)")
            return
        }

        let ocr = OCRService()
        let result = try await ocr.recognizeText(from: image)
        let lower = result.text.lowercased()

        XCTAssertFalse(
            result.text.isEmpty,
            "OCR liefert leeren Text — Vision-Pipeline ist gebrochen."
        )

        // Selektive, robuste Anker: mindestens einer der typischen
        // Rechnungs-Marker muss in der OCR-Ausgabe vorkommen. Strenger als
        // "non-empty", aber robust gegenueber Vision-Versionsschwankungen,
        // die einzelne Worte mal anders ausspielen.
        let anchors = ["rechnung", "stadtwerke", "datum", "eur", "iban"]
        let hits = anchors.filter { lower.contains($0) }
        XCTAssertFalse(
            hits.isEmpty,
            "Kein einziger der Rechnungs-Anker \(anchors) im OCR-Output. Auszug (max 400 chars):\n\(result.text.prefix(400))"
        )
    }

    /// Rendert die erste Seite einer PDF in eine UIImage. Wir nutzen
    /// PDFPage.thumbnail(of:for:) statt manuellem CGContext — das vermeidet
    /// Koordinaten-System-Probleme (PDFKit: lower-left origin, UIKit:
    /// upper-left), die in einem ersten Versuch zu blanken Bildern fuehrten.
    private func renderFirstPageToUIImage(at url: URL, maxSide: CGFloat) -> UIImage? {
        guard let doc = PDFDocument(url: url),
              let page = doc.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = maxSide / max(bounds.width, bounds.height)
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        return page.thumbnail(of: size, for: .mediaBox)
    }
}
