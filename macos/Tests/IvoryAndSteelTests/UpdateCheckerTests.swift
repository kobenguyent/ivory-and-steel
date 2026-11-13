import XCTest
@testable import IvoryAndSteel

// MARK: - Mock Network Session for GitHub Releases API

final class MockUpdateNetworkSession: UpdateNetworkSessionProtocol, @unchecked Sendable {
    var handler: ((URLRequest) throws -> (Data, URLResponse))?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let handler = handler else {
            throw URLError(.badServerResponse)
        }
        return try handler(request)
    }
}

final class MockUpdateChecker: UpdateCheckerProtocol, @unchecked Sendable {
    let repository: String = "kobenguyent/ivory-and-steel"
    let currentVersion: String
    var stubbedStatus: UpdateStatus

    var releasesWebURL: URL {
        URL(string: "https://github.com/\(repository)/releases")!
    }

    init(currentVersion: String = "1.0.0", stubbedStatus: UpdateStatus) {
        self.currentVersion = currentVersion
        self.stubbedStatus = stubbedStatus
    }

    func checkForUpdates(includePrereleases: Bool) async -> UpdateStatus {
        return stubbedStatus
    }
}

final class UpdateCheckerTests: XCTestCase {

    // MARK: - SemanticVersion Parsing & Comparison

    func testSemanticVersionParsingAndComparison() {
        let v1_0_0 = SemanticVersion("v1.0.0")
        let v1_0_1 = SemanticVersion("1.0.1")
        let v1_2_0 = SemanticVersion("v1.2.0")
        let v1_10_0 = SemanticVersion("v1.10.0")
        let v2_0 = SemanticVersion("v2.0")
        let v1_2_0_beta = SemanticVersion("v1.2.0-beta.1")
        let v1_2_0_build = SemanticVersion("v1.2.0+20261113")

        XCTAssertNotNil(v1_0_0)
        XCTAssertNotNil(v1_0_1)
        XCTAssertNotNil(v1_2_0)
        XCTAssertNotNil(v1_10_0)
        XCTAssertEqual(v2_0, SemanticVersion(major: 2, minor: 0, patch: 0))
        XCTAssertEqual(v1_2_0_build, v1_2_0)

        XCTAssertTrue(v1_0_0! < v1_0_1!)
        XCTAssertTrue(v1_2_0! < v1_10_0!, "1.10.0 must be numerically greater than 1.2.0")
        XCTAssertTrue(v1_2_0_beta! < v1_2_0!, "Pre-release must have lower precedence than normal release")
        XCTAssertTrue(v1_0_0! < v1_2_0_beta!, "1.2.0-beta.1 must be newer than 1.0.0")
        XCTAssertNil(SemanticVersion("not-a-version"))
    }

    // MARK: - GitHubReleaseInfo Asset Selection

    func testGitHubReleaseAssetResolution() throws {
        let json = """
        {
          "tag_name": "v1.2.0",
          "name": "Ivory & Steel v1.2.0",
          "body": "### Highlights\\n- Added GitHub Releases Auto-Updater",
          "html_url": "https://github.com/kobenguyent/ivory-and-steel/releases/tag/v1.2.0",
          "published_at": "2026-11-13T15:00:00Z",
          "draft": false,
          "prerelease": false,
          "assets": [
            {
              "name": "IvoryAndSteel.zip",
              "browser_download_url": "https://github.com/kobenguyent/ivory-and-steel/releases/download/v1.2.0/IvoryAndSteel.zip",
              "size": 4194304,
              "content_type": "application/zip"
            },
            {
              "name": "IvoryAndSteel.dmg",
              "browser_download_url": "https://github.com/kobenguyent/ivory-and-steel/releases/download/v1.2.0/IvoryAndSteel.dmg",
              "size": 4613734,
              "content_type": "application/x-apple-diskimage"
            }
          ]
        }
        """.data(using: .utf8)!

        let release = try JSONDecoder().decode(GitHubReleaseInfo.self, from: json)
        XCTAssertEqual(release.cleanVersionString, "1.2.0")
        XCTAssertEqual(release.dmgAsset?.name, "IvoryAndSteel.dmg")
        XCTAssertEqual(release.dmgAsset?.formattedSize, "4.4 MB")
        XCTAssertEqual(release.zipAsset?.name, "IvoryAndSteel.zip")
        XCTAssertEqual(
            release.preferredDownloadURL?.absoluteString,
            "https://github.com/kobenguyent/ivory-and-steel/releases/download/v1.2.0/IvoryAndSteel.dmg"
        )
    }

    // MARK: - UpdateChecker Network Scenarios

    func testCheckForUpdatesDetectsNewerRelease() async {
        let session = MockUpdateNetworkSession()
        session.handler = { request in
            let payload = """
            {
              "tag_name": "v1.3.0",
              "name": "Ivory & Steel v1.3.0",
              "body": "Bug fixes and acoustic engine improvements.",
              "html_url": "https://github.com/kobenguyent/ivory-and-steel/releases/tag/v1.3.0",
              "draft": false,
              "prerelease": false,
              "assets": []
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (payload, response)
        }

        let checker = UpdateChecker(
            repository: "kobenguyent/ivory-and-steel",
            currentVersion: "1.0.0",
            session: session
        )

        let status = await checker.checkForUpdates(includePrereleases: false)
        if case .updateAvailable(let release, let current) = status {
            XCTAssertEqual(release.tagName, "v1.3.0")
            XCTAssertEqual(current, "1.0.0")
        } else {
            XCTFail("Expected .updateAvailable, got \(status)")
        }
    }

    func testCheckForUpdatesReportsUpToDateWhenSameOrOlder() async {
        let session = MockUpdateNetworkSession()
        session.handler = { request in
            let payload = """
            {
              "tag_name": "v1.0.0",
              "name": "Ivory & Steel v1.0.0",
              "body": "Initial release.",
              "html_url": "https://github.com/kobenguyent/ivory-and-steel/releases/tag/v1.0.0",
              "draft": false,
              "prerelease": false,
              "assets": []
            }
            """.data(using: .utf8)!
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (payload, response)
        }

        let checker = UpdateChecker(
            repository: "kobenguyent/ivory-and-steel",
            currentVersion: "1.0.0",
            session: session
        )

        let status = await checker.checkForUpdates(includePrereleases: false)
        if case .upToDate(let current, _) = status {
            XCTAssertEqual(current, "1.0.0")
        } else {
            XCTFail("Expected .upToDate, got \(status)")
        }
    }

    func testCheckForUpdatesGracefullyHandlesNoPublishedReleases404() async {
        let session = MockUpdateNetworkSession()
        session.handler = { request in
            let urlStr = request.url?.absoluteString ?? ""
            if urlStr.hasSuffix("/releases/latest") {
                let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return (Data("{}".utf8), response)
            } else {
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (Data("[]".utf8), response)
            }
        }

        let checker = UpdateChecker(
            repository: "kobenguyent/ivory-and-steel",
            currentVersion: "1.0.0",
            session: session
        )

        let status = await checker.checkForUpdates(includePrereleases: false)
        if case .upToDate(let current, _) = status {
            XCTAssertEqual(current, "1.0.0")
        } else {
            XCTFail("Expected .upToDate when no releases are published yet, got \(status)")
        }
    }

    func testCheckForUpdatesHandlesRateLimitError() async {
        let session = MockUpdateNetworkSession()
        session.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!
            return (Data("{}".utf8), response)
        }

        let checker = UpdateChecker(
            repository: "kobenguyent/ivory-and-steel",
            currentVersion: "1.0.0",
            session: session
        )

        let status = await checker.checkForUpdates(includePrereleases: false)
        if case .error(let message) = status {
            XCTAssertTrue(message.contains("rate limit"))
        } else {
            XCTFail("Expected .error for HTTP 403, got \(status)")
        }
    }

    // MARK: - AppState Update Check & Skipped Release Behavior

    @MainActor
    func testAppStateUpdateCheckAndSkipRelease() async {
        let sampleRelease = GitHubReleaseInfo(
            tagName: "v2.0.0",
            name: "Ivory & Steel 2.0",
            body: "Major update",
            htmlUrl: "https://github.com/kobenguyent/ivory-and-steel/releases/tag/v2.0.0"
        )
        let mockChecker = MockUpdateChecker(
            currentVersion: "1.0.0",
            stubbedStatus: .updateAvailable(release: sampleRelease, currentVersion: "1.0.0")
        )

        // Reset skipped tag before test
        StorageManager.shared.updateSettings { $0.skippedReleaseTag = nil }

        let state = AppState(updateChecker: mockChecker)
        await state.performUpdateCheck(userInitiated: false)

        XCTAssertEqual(state.updateStatus.availableRelease?.tagName, "v2.0.0")
        XCTAssertTrue(state.showingUpdateSheet, "Automatic check should present sheet for unskipped release")

        // Skip v2.0.0
        state.skipRelease(tag: "v2.0.0")
        XCTAssertFalse(state.showingUpdateSheet)

        // Next automatic check should NOT pop the sheet for skipped v2.0.0
        state.updateStatus = .idle
        await state.performUpdateCheck(userInitiated: false)
        XCTAssertFalse(state.showingUpdateSheet, "Automatic check should respect skippedReleaseTag")

        // Manual check (userInitiated: true) SHOULD still present the sheet
        state.updateStatus = .idle
        await state.performUpdateCheck(userInitiated: true)
        XCTAssertTrue(state.showingUpdateSheet, "User-initiated check must always open the update sheet")

        // Cleanup
        StorageManager.shared.updateSettings { $0.skippedReleaseTag = nil }
    }
}
