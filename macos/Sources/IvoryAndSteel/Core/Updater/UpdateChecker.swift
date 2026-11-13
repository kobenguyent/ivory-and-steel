import Foundation

// MARK: - Semantic Versioning (SemVer 2.0)

/// Parses and compares semantic version strings (e.g., "v1.0.0", "1.2.3-beta.1").
public struct SemanticVersion: Comparable, Equatable, Sendable, CustomStringConvertible {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?

    public var description: String {
        if let pre = prerelease, !pre.isEmpty {
            return "\(major).\(minor).\(patch)-\(pre)"
        }
        return "\(major).\(minor).\(patch)"
    }

    public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
    }

    /// Parses a version tag or string such as `"v1.2.0"`, `"1.2.0-rc.1"`, or `"1.2"`.
    public init?(_ rawString: String) {
        var cleaned = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("v") || cleaned.hasPrefix("V") {
            cleaned.removeFirst()
        }

        // Strip build metadata (+...)
        if let plusIndex = cleaned.firstIndex(of: "+") {
            cleaned = String(cleaned[..<plusIndex])
        }

        // Split prerelease (-...)
        var prereleasePart: String? = nil
        if let dashIndex = cleaned.firstIndex(of: "-") {
            let afterDash = String(cleaned[cleaned.index(after: dashIndex)...])
            if !afterDash.isEmpty {
                prereleasePart = afterDash
            }
            cleaned = String(cleaned[..<dashIndex])
        }

        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty, parts.count <= 3 else { return nil }

        guard let maj = Int(parts[0]) else { return nil }
        let min: Int
        if parts.count >= 2 {
            guard let m = Int(parts[1]) else { return nil }
            min = m
        } else {
            min = 0
        }

        let pat: Int
        if parts.count == 3 {
            guard let p = Int(parts[2]) else { return nil }
            pat = p
        } else {
            pat = 0
        }

        self.major = maj
        self.minor = min
        self.patch = pat
        self.prerelease = prereleasePart
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Per SemVer 2.0: a normal version has higher precedence than a pre-release version
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil):
            return false
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (.some(let lPre), .some(let rPre)):
            return lPre.localizedStandardCompare(rPre) == .orderedAscending
        }
    }
}

// MARK: - GitHub Release Models

public struct GitHubReleaseAsset: Codable, Equatable, Sendable, Identifiable {
    public var id: String { name }
    public let name: String
    public let browserDownloadUrl: String
    public let size: Int
    public let contentType: String?

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
        case contentType = "content_type"
    }

    public init(
        name: String,
        browserDownloadUrl: String,
        size: Int,
        contentType: String? = nil
    ) {
        self.name = name
        self.browserDownloadUrl = browserDownloadUrl
        self.size = size
        self.contentType = contentType
    }

    /// Formatted file size (e.g., "4.4 MB")
    public var formattedSize: String {
        let mb = Double(size) / (1024.0 * 1024.0)
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        }
        let kb = Double(size) / 1024.0
        return String(format: "%.0f KB", max(1.0, kb))
    }
}

public struct GitHubReleaseInfo: Codable, Equatable, Sendable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?
    public let draft: Bool
    public let prerelease: Bool
    public let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case draft
        case prerelease
        case assets
    }

    public init(
        tagName: String,
        name: String? = nil,
        body: String? = nil,
        htmlUrl: String,
        publishedAt: String? = nil,
        draft: Bool = false,
        prerelease: Bool = false,
        assets: [GitHubReleaseAsset] = []
    ) {
        self.tagName = tagName
        self.name = name
        self.body = body
        self.htmlUrl = htmlUrl
        self.publishedAt = publishedAt
        self.draft = draft
        self.prerelease = prerelease
        self.assets = assets
    }

    /// Version string without leading 'v' prefix.
    public var cleanVersionString: String {
        if let semver = SemanticVersion(tagName) {
            return semver.description
        }
        return tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
    }

    /// Best human-readable release title.
    public var displayTitle: String {
        if let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return "Ivory & Steel \(tagName)"
    }

    /// Preferred `.dmg` disk image asset for macOS installation.
    public var dmgAsset: GitHubReleaseAsset? {
        let dmgAssets = assets.filter { $0.name.lowercased().hasSuffix(".dmg") }
        return dmgAssets.first(where: { $0.name == "IvoryAndSteel.dmg" }) ?? dmgAssets.first
    }

    /// Preferred `.zip` archive asset for macOS installation.
    public var zipAsset: GitHubReleaseAsset? {
        let zipAssets = assets.filter { $0.name.lowercased().hasSuffix(".zip") }
        return zipAssets.first(where: { $0.name == "IvoryAndSteel.zip" }) ?? zipAssets.first
    }

    /// Best direct download URL (.dmg first, then .zip, then GitHub release page).
    public var preferredDownloadURL: URL? {
        if let dmg = dmgAsset, let url = URL(string: dmg.browserDownloadUrl) {
            return url
        }
        if let zip = zipAsset, let url = URL(string: zip.browserDownloadUrl) {
            return url
        }
        return URL(string: htmlUrl)
    }

    /// URL to the GitHub Release page.
    public var releasePageURL: URL? {
        URL(string: htmlUrl)
    }

    /// Formatted publication date string if `publishedAt` is valid ISO-8601.
    public var formattedPublishedDate: String? {
        guard let publishedAt = publishedAt else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: publishedAt) {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return nil
    }
}

// MARK: - Update Check Status & Protocols

public enum UpdateStatus: Equatable, Sendable {
    case idle
    case checking
    case upToDate(currentVersion: String, checkedAt: Date)
    case updateAvailable(release: GitHubReleaseInfo, currentVersion: String)
    case error(message: String)

    public var isChecking: Bool {
        if case .checking = self { return true }
        return false
    }

    public var availableRelease: GitHubReleaseInfo? {
        if case .updateAvailable(let release, _) = self {
            return release
        }
        return nil
    }
}

public protocol UpdateNetworkSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: UpdateNetworkSessionProtocol {}

public protocol UpdateCheckerProtocol: Sendable {
    var repository: String { get }
    var currentVersion: String { get }
    var releasesWebURL: URL { get }
    func checkForUpdates(includePrereleases: Bool) async -> UpdateStatus
}

// MARK: - GitHub Releases Update Checker

/// Queries GitHub Releases API (`https://api.github.com/repos/{owner}/{repo}/releases`)
/// and compares semantic versions against the running macOS app bundle.
public final class UpdateChecker: UpdateCheckerProtocol, @unchecked Sendable {
    public static let defaultRepository = "kobenguyent/ivory-and-steel"
    public static let shared = UpdateChecker()

    public let repository: String
    public let currentVersion: String
    private let session: UpdateNetworkSessionProtocol

    public var releasesWebURL: URL {
        URL(string: "https://github.com/\(repository)/releases")!
    }

    public init(
        repository: String? = nil,
        currentVersion: String? = nil,
        session: UpdateNetworkSessionProtocol = URLSession.shared
    ) {
        if let repo = repository, !repo.isEmpty {
            self.repository = repo
        } else if let plistRepo = Bundle.main.infoDictionary?["GitHubRepository"] as? String, !plistRepo.isEmpty {
            self.repository = plistRepo
        } else {
            self.repository = Self.defaultRepository
        }

        if let ver = currentVersion, !ver.isEmpty {
            self.currentVersion = ver
        } else if let plistVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !plistVer.isEmpty {
            self.currentVersion = plistVer
        } else {
            self.currentVersion = "1.0.0"
        }

        self.session = session
    }

    /// Checks GitHub Releases for a newer version than `currentVersion`.
    public func checkForUpdates(includePrereleases: Bool = false) async -> UpdateStatus {
        do {
            let candidateRelease: GitHubReleaseInfo?
            if includePrereleases {
                candidateRelease = try await fetchLatestFromList(includePrereleases: true)
            } else {
                if let latest = try await fetchLatestReleaseEndpoint() {
                    candidateRelease = latest
                } else {
                    // Fallback when /releases/latest returns 404 (e.g., no published releases yet)
                    candidateRelease = try await fetchLatestFromList(includePrereleases: false)
                }
            }

            guard let release = candidateRelease else {
                // Repository has no published releases yet -> treat current version as up to date
                return .upToDate(currentVersion: currentVersion, checkedAt: Date())
            }

            if Self.isNewerVersion(remoteTag: release.tagName, currentVersion: currentVersion) {
                return .updateAvailable(release: release, currentVersion: currentVersion)
            } else {
                return .upToDate(currentVersion: currentVersion, checkedAt: Date())
            }
        } catch let error as UpdateCheckError {
            return .error(message: error.localizedDescription)
        } catch {
            return .error(message: "Unable to reach GitHub Releases (\(error.localizedDescription)).")
        }
    }

    /// Compares two version tags using Semantic Versioning.
    public static func isNewerVersion(remoteTag: String, currentVersion: String) -> Bool {
        guard let remoteSemVer = SemanticVersion(remoteTag),
              let localSemVer = SemanticVersion(currentVersion) else {
            return false
        }
        return remoteSemVer > localSemVer
    }

    // MARK: - Private Network Helpers

    private enum UpdateCheckError: LocalizedError {
        case invalidURL
        case rateLimited
        case serverError(Int)
        case invalidPayload

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid GitHub Releases API URL."
            case .rateLimited:
                return "GitHub API rate limit exceeded. Please try again later."
            case .serverError(let code):
                return "GitHub Releases API returned HTTP \(code)."
            case .invalidPayload:
                return "Could not parse GitHub Releases response."
            }
        }
    }

    private func makeRequest(urlString: String) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw UpdateCheckError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("IvoryAndSteel-macOS/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetchLatestReleaseEndpoint() async throws -> GitHubReleaseInfo? {
        let request = try makeRequest(urlString: "https://api.github.com/repos/\(repository)/releases/latest")
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw UpdateCheckError.invalidPayload
        }

        switch http.statusCode {
        case 200:
            do {
                let release = try JSONDecoder().decode(GitHubReleaseInfo.self, from: data)
                if release.draft || release.prerelease {
                    return nil
                }
                return release
            } catch {
                throw UpdateCheckError.invalidPayload
            }
        case 404:
            // 404 on /releases/latest means no non-prerelease release is published yet
            return nil
        case 403, 429:
            throw UpdateCheckError.rateLimited
        default:
            throw UpdateCheckError.serverError(http.statusCode)
        }
    }

    private func fetchLatestFromList(includePrereleases: Bool) async throws -> GitHubReleaseInfo? {
        let request = try makeRequest(urlString: "https://api.github.com/repos/\(repository)/releases?per_page=10")
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw UpdateCheckError.invalidPayload
        }

        switch http.statusCode {
        case 200:
            do {
                let releases = try JSONDecoder().decode([GitHubReleaseInfo].self, from: data)
                let eligible = releases.filter { release in
                    !release.draft && (includePrereleases || !release.prerelease)
                }
                // Return the highest semantic version among eligible releases
                return eligible.max { a, b in
                    guard let verA = SemanticVersion(a.tagName),
                          let verB = SemanticVersion(b.tagName) else {
                        return false
                    }
                    return verA < verB
                }
            } catch {
                throw UpdateCheckError.invalidPayload
            }
        case 404:
            return nil
        case 403, 429:
            throw UpdateCheckError.rateLimited
        default:
            throw UpdateCheckError.serverError(http.statusCode)
        }
    }
}
