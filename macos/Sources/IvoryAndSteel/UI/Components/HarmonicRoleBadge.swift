import SwiftUI

/// Harmonic Role Badge displaying musical function ("ROOT", "3RD", "5TH", "7TH", or interval degrees).
/// Rendered with Apple-tier typographic restraint:
/// - ROOT badge features an elegant warm champagne gold accent.
/// - Degree badges render in a sleek, neutral frosted-glass capsule.
public struct HarmonicRoleBadge: View {
    public enum Size {
        case mini       // Fretboard & compact keybeds
        case compact    // Inline compact badges
        case small      // Keybed headers & toolbars
        case regular    // Standard card badges
        case prominent  // Hero callouts
        
        var fontSize: CGFloat {
            switch self {
            case .mini: return 8
            case .compact: return 8.5
            case .small: return 9
            case .regular: return 10
            case .prominent: return 12
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .mini: return 4
            case .compact: return 5
            case .small: return 6
            case .regular: return 7
            case .prominent: return 9
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .mini: return 1.5
            case .compact: return 2
            case .small: return 2
            case .regular: return 3
            case .prominent: return 4
            }
        }
    }
    
    public let role: String
    public let isRoot: Bool
    public let size: Size
    public let showIcon: Bool
    
    public init(
        _ role: String,
        isRoot: Bool? = nil,
        size: Size = .regular,
        showIcon: Bool = false
    ) {
        self.role = role
        let normalized = role.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.isRoot = isRoot ?? (normalized == "ROOT" || normalized == "1" || normalized == "1ST" || normalized == "R")
        self.size = size
        self.showIcon = showIcon
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            Text(displayTitle)
                .font(.system(size: size.fontSize, weight: isRoot ? .bold : .medium, design: .monospaced))
                .tracking(0.6)
                .foregroundColor(isRoot ? Color.musicianEbony : Color.white.opacity(0.85))
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            isRoot
                ? Color.musicianGold
                : Color.white.opacity(0.08)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    isRoot ? Color.musicianGoldLight.opacity(0.6) : Color.white.opacity(0.1),
                    lineWidth: 0.6
                )
        )
    }
    
    private var displayTitle: String {
        let trimmed = role.trimmingCharacters(in: .whitespacesAndNewlines)
        if isRoot {
            return "ROOT"
        }
        return trimmed.uppercased()
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            HarmonicRoleBadge("ROOT", size: .prominent)
            HarmonicRoleBadge("3RD", size: .prominent)
            HarmonicRoleBadge("5TH", size: .prominent)
            HarmonicRoleBadge("7TH", size: .prominent)
        }
        HStack(spacing: 8) {
            HarmonicRoleBadge("ROOT", size: .regular)
            HarmonicRoleBadge("3rd", size: .regular)
            HarmonicRoleBadge("b5", size: .regular)
            HarmonicRoleBadge("m7", size: .regular)
        }
        HStack(spacing: 6) {
            HarmonicRoleBadge("ROOT", size: .mini)
            HarmonicRoleBadge("3RD", size: .mini)
            HarmonicRoleBadge("5TH", size: .mini)
        }
    }
    .padding()
    .background(Color.musicianEbony)
}
