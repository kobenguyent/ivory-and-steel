import SwiftUI

// MARK: - Luxury Concert Grand & Boutique Luthier Apple-Tier Design Tokens

public extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    // Core Brand Colors (Restrained Warm Champagne Gold)
    static let musicianGold = Color(hex: 0xD4AF37)
    static let musicianGoldLight = Color(hex: 0xF0D882)
    static let musicianGoldDark = Color(hex: 0x9E8124)
    
    // Keybed & Enclosure Colors (Deep Neutral Ebony & Matte Charcoal)
    static let musicianEbony = Color(hex: 0x0E0F14)
    static let musicianCharcoal = Color(hex: 0x161820)
    static let musicianSurface = Color(hex: 0x12131A)
    static let musicianCard = Color(hex: 0x15161E)
    static let musicianIvory = Color(hex: 0xFDFBF7)
    static let musicianIvoryPressed = Color(hex: 0xEDE7DC)
    
    // Steinway Felt Rail (Subtle Deep Burgundy Velvet, Never Screaming Red)
    static let steinwayCrimson = Color(hex: 0x5C1822)
    static let steinwayCrimsonDark = Color(hex: 0x380D14)
    
    // Harmonic Functional Colors (Muted, Elegant, Never Neon AI Party Lights)
    static let tonicGold = Color(hex: 0xD4AF37)
    static let subdominantEmerald = Color(hex: 0x6EE7B7) // Soft sea-foam mint
    static let dominantSky = Color(hex: 0x93C5FD)        // Soft muted sky mist
    static let minorPurple = Color(hex: 0xC4B5FD)       // Soft lavender mist
    static let amberGlow = Color(hex: 0xEAB308)
    
    // Apple-Tier Glass Surfaces & Hairlines
    static let glassSurface = Color.white.opacity(0.035)
    static let glassSurfaceHover = Color.white.opacity(0.065)
    static let glassBorder = Color.white.opacity(0.06)
    static let glassBorderSubtle = Color.white.opacity(0.03)
    static let hairlineDivider = Color.white.opacity(0.06)
    static let goldHairline = Color.musicianGold.opacity(0.18)
    static let sidebarActiveTint = Color.white.opacity(0.12)
}

public extension LinearGradient {
    static let goldGlow = LinearGradient(
        colors: [Color.musicianGoldLight, Color.musicianGold, Color.musicianGoldDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Understated Concert Grand Fallboard Strip
    static let steinwayFelt = LinearGradient(
        colors: [Color.steinwayCrimsonDark, Color.steinwayCrimson, Color.steinwayCrimsonDark],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Authentic Acoustic Ivory Keybed (Clean off-white, zero yellow tinting)
    static let ivoryKey = LinearGradient(
        colors: [Color(hex: 0xFFFFFF), Color(hex: 0xFAF9F5), Color(hex: 0xF2ECE1)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Acoustic Key Depression (Natural shadow gradient, zero cheese-yellow)
    static let ivoryKeyPressed = LinearGradient(
        colors: [Color(hex: 0xEDE7DC), Color(hex: 0xE2DAC9), Color(hex: 0xD7CDBC)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Satin Ebony Black Key (Matte dark graphite)
    static let ebonyKey = LinearGradient(
        colors: [Color(hex: 0x282B34), Color(hex: 0x1A1C22), Color(hex: 0x0E0F12)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let ebonyKeyPressed = LinearGradient(
        colors: [Color(hex: 0x181920), Color(hex: 0x121317), Color(hex: 0x08090A)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Natural Luthier Rosewood
    static let fretboardRosewood = LinearGradient(
        colors: [Color(hex: 0x1E1510), Color(hex: 0x2A1B14), Color(hex: 0x18100B)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Fine Nickel-Silver Fret Wire
    static let metallicFret = LinearGradient(
        colors: [Color(hex: 0xD1D5DB), Color(hex: 0x9CA3AF), Color(hex: 0xCBD5E1)],
        startPoint: .top,
        endPoint: .bottom
    )
}
