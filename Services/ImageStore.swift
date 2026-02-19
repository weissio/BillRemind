import Foundation
import UIKit

struct ImageStore {
    private let directoryName = "InvoicesImages"

    private var directoryURL: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(directoryName, isDirectory: true)
    }

    func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func save(image: UIImage, id: UUID) throws -> String {
        try ensureDirectoryExists()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw ImageStoreError.encodingFailed
        }
        try data.write(to: fileURL, options: .atomic)
        return fileName
    }

    func loadImage(fileName: String) -> UIImage? {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    func deleteImage(fileName: String?) {
        guard let fileName else { return }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

enum ImageStoreError: Error {
    case encodingFailed
}
