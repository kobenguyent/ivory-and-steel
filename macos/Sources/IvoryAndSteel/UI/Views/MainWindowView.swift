import SwiftUI
import AppKit

// MARK: - Native macOS Visual Effect Vibrancy Glass

public struct VisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    
    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Main Window View

/// Main Window View for Ivory & Steel Native macOS.
/// Implements a pure Apple-glassmorphic sidebar with matched-geometry sliding glass pill,
/// native NSVisualEffectView vibrancy, and unified window toolbar.
public struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var showingSettingsSheet: Bool = false
    @Namespace private var sidebarAnimationNamespace
    @State private var hoveredTab: AppTab? = nil
    @State private var isMetronomeHovered: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 260)
        } detail: {
            ZStack {
                detailContent
                    .id(appState.selectedTab)
                    .transition(.studioPage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.musicianEbony)
            .animation(StudioMotion.sheetReveal, value: appState.selectedTab)
        }
        .toolbar {
            toolbarItems
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView {
                showingSettingsSheet = false
            }
            .frame(minWidth: 720, idealWidth: 760, minHeight: 610, idealHeight: 660)
            .background(Color.musicianEbony)
            .preferredColorScheme(.dark)
        }
        .sheet(
            isPresented: Binding(
                get: { appState.showingUpdateSheet },
                set: { appState.showingUpdateSheet = $0 }
            )
        ) {
            UpdateSheetView()
                .environment(appState)
        }
    }
    
    // MARK: - Apple Glassmorphism Sidebar
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            // App Wordmark
            HStack(spacing: 10) {
                Image(systemName: "pianokeys")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.musicianGold)

                Text("Ivory & Steel")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(Color.musicianIvory)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)
            
            // Subtle Hairline Divider
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
                .padding(.horizontal, 12)
            
            // Smooth Sliding Glass Tabs
            ScrollView {
                VStack(spacing: 3) {
                    ForEach(AppTab.allCases) { tab in
                        let isSelected = (appState.selectedTab == tab)
                        let isHovered = (hoveredTab == tab)
                        
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                                appState.selectedTab = tab
                            }
                        } label: {
                            HStack(spacing: 11) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 13.5, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(
                                        isSelected
                                            ? Color.white
                                            : Color.white.opacity(isHovered ? 0.9 : 0.6)
                                    )
                                    .symbolEffect(.bounce, value: isSelected)
                                    .frame(width: 20)
                                
                                Text(tab.rawValue)
                                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(
                                        isSelected
                                            ? Color.white
                                            : Color.white.opacity(isHovered ? 0.95 : 0.72)
                                    )
                                
                                Spacer()
                            }
                            .offset(x: isHovered && !isSelected ? 2 : 0)
                            .padding(.vertical, 7.5)
                            .padding(.horizontal, 11)
                            .background {
                                ZStack {
                                    // Matched Geometry Sliding Frosted Glass Pill
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.white.opacity(0.12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(
                                                        LinearGradient(
                                                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.06)],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        ),
                                                        lineWidth: 0.8
                                                    )
                                            )
                                            .shadow(color: Color.black.opacity(0.25), radius: 5, y: 2)
                                            .matchedGeometryEffect(id: "sidebar_active_glass_pill", in: sidebarAnimationNamespace)
                                    } else if isHovered {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.white.opacity(0.045))
                                    }
                                }
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.16)) {
                                if hovering {
                                    hoveredTab = tab
                                } else if hoveredTab == tab {
                                    hoveredTab = nil
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
            }
            
            Spacer(minLength: 16)
            
            sidebarUpdateFooter
        }
        .background {
            ZStack {
                // Native macOS Sidebar Visual Effect Vibrancy Blur
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                
                // Deep luxury tinted translucent wash (zero opaque solid colors)
                Color(hex: 0x0E0F15, opacity: 0.78)
            }
        }
    }
    
    // MARK: - Sidebar Update Footer
    
    private var sidebarUpdateFooter: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
                .padding(.horizontal, 12)
            
            if case .updateAvailable(let release, _) = appState.updateStatus {
                Button(action: {
                    appState.showingUpdateSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.musicianEbony)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Update Available")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.musicianEbony)
                            Text("Download \(release.tagName)")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.musicianEbony.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.musicianEbony)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Color.musicianGold)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            } else {
                Button(action: {
                    appState.checkForUpdates(userInitiated: true)
                }) {
                    HStack(spacing: 6) {
                        if appState.updateStatus.isChecking {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                        
                        Text("v\(appState.currentAppVersion)")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.55))
                        
                        Spacer()
                        
                        Text(appState.updateStatus.isChecking ? "Checking…" : "Check Updates")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.musicianGold.opacity(0.85))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 6)
                .padding(.bottom, 10)
            }
        }
    }
    
    // MARK: - Detail Content Routing
    
    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedTab {
        case .theoryExplorer:
            TheoryExplorerView()
        case .virtualPiano:
            VirtualPianoStudioView()
        case .guitarFretboard:
            GuitarFretboardStudioView()
        case .metronome:
            MetronomeStudioView()
        case .practiceRoutine:
            PracticeRoutineView()
        case .masterclassHub:
            MasterclassHubView()
        case .musicianQuiz:
            MusicianQuizView()
        }
    }
    
    // MARK: - Toolbar Items (Apple HIG Floating Glass Capsules)
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 4) {
                // Unified Key Selector (Sits natively inside macOS toolbar glass — zero nested double-bezel borders)
                LuxuryDropdown(
                    selection: Binding(
                        get: { appState.rootKey },
                        set: { appState.setRootKey($0) }
                    ),
                    options: KeyDefinitions.chromaticRoots.map { key in
                        let info = KeyDefinitions.keyInfo(for: key)
                        let accLabel = info.accidentalType == "natural"
                            ? "♮"
                            : (info.accidentalType == "sharp" ? "\(info.sharpsCount)♯" : "\(info.flatsCount)♭")
                        return LuxuryDropdownOption(
                            value: key,
                            title: "Key of \(key.replacingOccurrences(of: "b", with: "♭"))",
                            subtitle: "Rel. \(info.relativeMinor)",
                            badge: accLabel
                        )
                    },
                    popoverWidth: 230,
                    maxPopoverHeight: 340,
                    shape: .capsule
                ) { isOpen, isHovered in
                    HStack(spacing: 5.5) {
                        Circle()
                            .fill(Color.musicianGold)
                            .frame(width: 6.5, height: 6.5)
                        
                        HStack(spacing: 3.5) {
                            Text("Key:")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.55))
                            
                            Text("\(appState.rootKey.replacingOccurrences(of: "b", with: "♭")) Major")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isOpen ? Color.musicianGoldLight : Color.musicianIvory)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(isOpen ? Color.musicianGold : Color.white.opacity(0.45))
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isOpen)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(
                        Capsule().fill(
                            isOpen
                                ? Color.musicianGold.opacity(0.14)
                                : (isHovered ? Color.white.opacity(0.08) : Color.clear)
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            isOpen ? Color.musicianGold.opacity(0.42) : Color.clear,
                            lineWidth: 0.75
                        )
                    )
                }
                
                // Delicate Hairline Divider
                Rectangle()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 1, height: 13)
                
                // Metronome Quick Toggle (Matched height, baseline & hover responsiveness)
                Button(action: {
                    appState.toggleMetronome()
                }) {
                    HStack(spacing: 5.5) {
                        Image(systemName: appState.isMetronomePlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(appState.isMetronomePlaying ? Color.steinwayCrimson : Color.musicianGold)
                        
                        Text("\(Int(appState.metronomeBPM))")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(appState.isMetronomePlaying ? Color.musicianIvory : Color.musicianIvory)
                            .contentTransition(.numericText())
                        
                        Text("BPM")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(
                        Capsule().fill(
                            appState.isMetronomePlaying
                                ? Color.steinwayCrimson.opacity(0.16)
                                : (isMetronomeHovered ? Color.white.opacity(0.08) : Color.clear)
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(
                            appState.isMetronomePlaying ? Color.steinwayCrimson.opacity(0.45) : Color.clear,
                            lineWidth: 0.75
                        )
                    )
                    .contentShape(Capsule())
                }
                .studioPressable(scale: 0.96)
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.16)) {
                        isMetronomeHovered = hovering
                    }
                }
                .help(appState.isMetronomePlaying ? "Pause Metronome" : "Start Metronome (\(Int(appState.metronomeBPM)) BPM)")
            }
            .padding(.horizontal, 2)
            .fixedSize()
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: {
                appState.toggleMute()
            }) {
                Image(systemName: appState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundColor(appState.isMuted ? Color.steinwayCrimson : Color.musicianGold)
            }
            .help(appState.isMuted ? "Unmute Master Audio (⌥⌘M)" : "Mute Master Audio (⌥⌘M)")
            
            Button(action: {
                showingSettingsSheet = true
            }) {
                Image(systemName: "gearshape")
                    .foregroundColor(Color.white.opacity(0.85))
            }
            .help("Open Studio Settings")
        }
    }
}
