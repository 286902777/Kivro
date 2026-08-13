import AVFoundation
import UIKit

final class KivroVideoMedia {
    static let shared = KivroVideoMedia()

    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let thumbnailQueue = DispatchQueue(label: "app.kivro.video-thumbnail", qos: .userInitiated)

    private init() {}

    func bundledURL(resourceName: String) -> URL? {
        if FileManager.default.fileExists(atPath: resourceName) {
            return URL(fileURLWithPath: resourceName)
        }
        let value = resourceName as NSString
        let fileExtension = value.pathExtension
        let baseName = value.deletingPathExtension
        return Bundle.main.url(
            forResource: baseName,
            withExtension: fileExtension.isEmpty ? "mp4" : fileExtension
        )
    }

    func image(resourceName: String) -> UIImage? {
        if FileManager.default.fileExists(atPath: resourceName) {
            return UIImage(contentsOfFile: resourceName)
        }
        return UIImage(named: resourceName)
    }

    func persistImage(_ image: UIImage) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let directory = try mediaDirectory(named: "Images")
        let destinationURL = directory
            .appendingPathComponent(UUID().uuidString.lowercased())
            .appendingPathExtension("jpg")
        try data.write(to: destinationURL, options: .atomic)
        return destinationURL
    }

    func thumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        let key = videoURL.absoluteString as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            completion(cached)
            return
        }

        thumbnailQueue.async { [weak self] in
            let asset = AVURLAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 720, height: 720)
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            let image = (try? generator.copyCGImage(at: .zero, actualTime: nil)).map(UIImage.init(cgImage:))
            if let image {
                self?.thumbnailCache.setObject(image, forKey: key)
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func persistPickedVideo(from sourceURL: URL) throws -> URL {
        let directory = try mediaDirectory(named: "Videos")
        let destinationURL = directory
            .appendingPathComponent(UUID().uuidString.lowercased())
            .appendingPathExtension(sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension)
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    func deletePersistedMedia(paths: [String]) {
        let fileManager = FileManager.default
        guard let supportDirectory = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("Kivro", isDirectory: true) else { return }
        let allowedPrefix = supportDirectory.standardizedFileURL.path + "/"

        paths.forEach { path in
            let url = URL(fileURLWithPath: path).standardizedFileURL
            guard url.path.hasPrefix(allowedPrefix),
                  fileManager.fileExists(atPath: url.path) else { return }
            try? fileManager.removeItem(at: url)
        }
    }

    private func mediaDirectory(named name: String) throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseDirectory
            .appendingPathComponent("Kivro", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
