import Foundation

/// Crash-safe resource locator for bundled JSON assets (`TipsData.json`, `QuizData.json`).
/// Avoids SwiftPM's auto-generated `Bundle.module` accessor, which calls `fatalError`
/// when a standalone `.app` bundle is moved away from the original build machine's `.build` path
/// or when `Bundle.main.bundleURL` is the `.app` root instead of `Contents/Resources`.
public enum ResourceLoader {
    private static let bundleName = "IvoryAndSteel_IvoryAndSteel.bundle"

    /// Safely resolves the URL for a bundled resource without ever invoking `fatalError`.
    public static func url(forResource name: String, withExtension ext: String) -> URL? {
        let fileName = ext.isEmpty ? name : "\(name).\(ext)"
        let fm = FileManager.default

        // 1. Direct lookup in Bundle.main (Contents/Resources/<name>.<ext>)
        if let mainURL = Bundle.main.url(forResource: name, withExtension: ext),
           fm.fileExists(atPath: mainURL.path) {
            return mainURL
        }

        // 2. Candidate directories where the resource or SPM .bundle may reside
        var candidateBaseURLs: [URL] = []
        if let resURL = Bundle.main.resourceURL {
            candidateBaseURLs.append(resURL)
        }
        candidateBaseURLs.append(Bundle.main.bundleURL)
        if let execDir = Bundle.main.executableURL?.deletingLastPathComponent() {
            candidateBaseURLs.append(execDir)
        }

        for base in candidateBaseURLs {
            let directFile = base.appendingPathComponent(fileName)
            if fm.fileExists(atPath: directFile.path) {
                return directFile
            }

            let nestedBundleResource = base
                .appendingPathComponent(bundleName)
                .appendingPathComponent("Contents/Resources")
                .appendingPathComponent(fileName)
            if fm.fileExists(atPath: nestedBundleResource.path) {
                return nestedBundleResource
            }

            let flatBundleResource = base
                .appendingPathComponent(bundleName)
                .appendingPathComponent(fileName)
            if fm.fileExists(atPath: flatBundleResource.path) {
                return flatBundleResource
            }

            let bundleURL = base.appendingPathComponent(bundleName)
            if let spmBundle = Bundle(url: bundleURL),
               let found = spmBundle.url(forResource: name, withExtension: ext),
               fm.fileExists(atPath: found.path) {
                return found
            }
        }

        // 3. Source tree fallback relative to #filePath (used during `swift test` and local dev)
        let sourceFileURL = URL(fileURLWithPath: #filePath)
        let sourceResourcesDir = sourceFileURL
            .deletingLastPathComponent() // Storage
            .deletingLastPathComponent() // Core
            .deletingLastPathComponent() // IvoryAndSteel
            .appendingPathComponent("Resources")
        let sourceResourceURL = sourceResourcesDir.appendingPathComponent(fileName)
        if fm.fileExists(atPath: sourceResourceURL.path) {
            return sourceResourceURL
        }

        // 4. Current working directory fallbacks
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let cwdCandidates = [
            cwd.appendingPathComponent("Sources/IvoryAndSteel/Resources/\(fileName)"),
            cwd.appendingPathComponent("macos/Sources/IvoryAndSteel/Resources/\(fileName)"),
            cwd.appendingPathComponent("Resources/\(fileName)")
        ]
        for candidate in cwdCandidates where fm.fileExists(atPath: candidate.path) {
            return candidate
        }

        return nil
    }

    /// Loads and decodes a JSON resource safely, returning nil if not found or invalid.
    public static func decodeJSON<T: Decodable>(_ type: T.Type, resource: String, withExtension ext: String = "json") -> T? {
        guard let url = self.url(forResource: resource, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
