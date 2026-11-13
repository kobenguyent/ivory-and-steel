import SwiftUI
import AppKit

/// Modal sheet displaying GitHub Releases update check status, release notes,
/// and direct installer download actions (.dmg / .zip).
public struct UpdateSheetView: View {
    @Environment(AppState.self) private var appState

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerSection

            Divider()
                .background(Color.musicianGold.opacity(0.2))

            statusContentSection

            Spacer(minLength: 4)

            Divider()
                .background(Color.musicianGold.opacity(0.2))

            footerActionsSection
        }
        .padding(24)
        .frame(width: 540, height: 420)
        .background(Color.musicianEbony)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.musicianGold.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.musicianGold.opacity(0.35), lineWidth: 1)
                    )

                Image(systemName: "arrow.down.circle.dotted")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.musicianGold)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("Ivory & Steel Software Update")
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Text("GitHub Releases • \(appState.updateChecker.repository)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.gray)
            }

            Spacer()

            Text("v\(appState.currentAppVersion)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.musicianSurface)
                .foregroundColor(Color.musicianGold)
                .clipShape(Capsule())
        }
    }

    // MARK: - Status Content

    @ViewBuilder
    private var statusContentSection: some View {
        switch appState.updateStatus {
        case .idle, .checking:
            checkingView
        case .upToDate(let currentVersion, let checkedAt):
            upToDateView(currentVersion: currentVersion, checkedAt: checkedAt)
        case .updateAvailable(let release, let currentVersion):
            updateAvailableView(release: release, currentVersion: currentVersion)
        case .error(let message):
            errorView(message: message)
        }
    }

    private var checkingView: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView()
                .controlSize(.regular)
                .tint(Color.musicianGold)

            Text("Checking GitHub Releases for new versions…")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.musicianIvory)

            Text("Querying api.github.com/repos/\(appState.updateChecker.repository)/releases")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func upToDateView(currentVersion: String, checkedAt: Date) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38))
                .foregroundColor(Color.subdominantEmerald)

            Text("You're running the latest version of Ivory & Steel")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)

            Text("Installed version v\(currentVersion) is up to date.")
                .font(.system(size: 12))
                .foregroundColor(Color.gray)

            Text("Last checked: \(checkedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundColor(Color.gray.opacity(0.8))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func updateAvailableView(release: GitHubReleaseInfo, currentVersion: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Version Banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(release.displayTitle)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(Color.musicianIvory)

                        if release.prerelease {
                            Text("PRE-RELEASE")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.musicianGold.opacity(0.2))
                                .foregroundColor(Color.musicianGold)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        Text("v\(currentVersion)")
                            .foregroundColor(Color.gray)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.musicianGold)
                        Text("v\(release.cleanVersionString)")
                            .foregroundColor(Color.subdominantEmerald)
                            .fontWeight(.bold)

                        if let pubDate = release.formattedPublishedDate {
                            Text("• Published \(pubDate)")
                                .foregroundColor(Color.gray)
                        }
                    }
                    .font(.system(size: 11, design: .monospaced))
                }

                Spacer()

                if let asset = release.dmgAsset ?? release.zipAsset {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(asset.name)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.musicianGold)
                        Text(asset.formattedSize)
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(Color.gray)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.musicianSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Release Notes
            Text("Release Notes")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.musicianGold)

            ScrollView {
                Text(cleanedReleaseNotes(release.body))
                    .font(.system(size: 11.5))
                    .foregroundColor(Color.musicianIvory.opacity(0.92))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(12)
            .frame(maxHeight: .infinity)
            .background(Color.musicianCard)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundColor(Color.steinwayCrimson)

            Text("Update Check Failed")
                .font(.system(size: 14, weight: .bold, design: .serif))
                .foregroundColor(Color.musicianIvory)

            Text(message)
                .font(.system(size: 11.5))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Retry Check") {
                appState.checkForUpdates(userInitiated: true)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.musicianCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Footer Actions

    private var footerActionsSection: some View {
        HStack(spacing: 10) {
            if case .updateAvailable(let release, _) = appState.updateStatus {
                Button("Skip This Version") {
                    appState.skipRelease(tag: release.tagName)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Color.gray)

                Spacer()

                if let releasePageURL = release.releasePageURL {
                    Button("View on GitHub") {
                        NSWorkspace.shared.open(releasePageURL)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Later") {
                    appState.showingUpdateSheet = false
                }
                .buttonStyle(.bordered)

                Button(action: {
                    if let downloadURL = release.preferredDownloadURL {
                        NSWorkspace.shared.open(downloadURL)
                    }
                    appState.showingUpdateSheet = false
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text(release.dmgAsset != nil ? "Download .DMG" : "Download Update")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundColor(Color.musicianEbony)
                    .background(Color.musicianGold)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else {
                Button("Open GitHub Releases") {
                    NSWorkspace.shared.open(appState.updateChecker.releasesWebURL)
                }
                .buttonStyle(.bordered)

                Spacer()

                if !appState.updateStatus.isChecking {
                    Button("Check Again") {
                        appState.checkForUpdates(userInitiated: true)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Done") {
                    appState.showingUpdateSheet = false
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.musicianGold)
                .foregroundColor(Color.musicianEbony)
            }
        }
    }

    private func cleanedReleaseNotes(_ raw: String?) -> String {
        guard let text = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return "A new release of Ivory & Steel is available for download on GitHub Releases."
        }
        return text
    }
}
