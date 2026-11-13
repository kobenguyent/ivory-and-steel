import SwiftUI

// MARK: - Unified Concert-Hall Motion System (Apple HIG Physical Choreography)

/// Curated spring and easing curves tuned for musical instruments and quiet macOS glass surfaces.
public enum StudioMotion {
    /// Crisp, damped spring for segmented tabs, chips, toggles, and dropdown chevrons.
    public static let snappyControl = Animation.spring(response: 0.26, dampingFraction: 0.82)
    
    /// Smooth architectural spring for workspace sections, accordions, and CAGED frame glides.
    public static let cardGlide = Animation.spring(response: 0.34, dampingFraction: 0.84)
    
    /// Gentle editorial spring for page switches, quiz transitions, and modal panels.
    public static let sheetReveal = Animation.spring(response: 0.38, dampingFraction: 0.86)
    
    /// Fast felt-hammer action curve for piano keys, fret nodes, and chime pulses.
    public static let keyAction = Animation.spring(response: 0.14, dampingFraction: 0.72)
    
    /// Quick pointer-hover luminance ease without spatial overshoot.
    public static let softHover = Animation.easeOut(duration: 0.16)
}

// MARK: - Asymmetric Editorial Transitions

public extension AnyTransition {
    /// Editorial section reveal: fades in while gently rising into place and fading cleanly out.
    static var studioSection: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: 7))
                .combined(with: .scale(scale: 0.985, anchor: .top)),
            removal: .opacity
        )
    }
    
    /// Subtle page transition for sidebar studio switching and quiz question progression.
    static var studioPage: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .offset(y: 6))
                .combined(with: .scale(scale: 0.992, anchor: .center)),
            removal: .opacity
        )
    }
    
    /// Compact horizontal pill reveal for inline toolbar/selector accessories.
    static var studioPill: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.94)),
            removal: .opacity
        )
    }
}

// MARK: - Tactile Interactive ButtonStyle

/// Subtle physical press-down compression for studio action buttons and interactive pills.
public struct StudioPressButtonStyle: ButtonStyle {
    public var pressedScale: CGFloat
    public var pressedOpacity: Double
    
    public init(pressedScale: CGFloat = 0.965, pressedOpacity: Double = 0.88) {
        self.pressedScale = pressedScale
        self.pressedOpacity = pressedOpacity
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(StudioMotion.keyAction, value: configuration.isPressed)
    }
}

public extension View {
    /// Applies consistent subtle press feel without altering button layout.
    func studioPressable(scale: CGFloat = 0.965) -> some View {
        buttonStyle(StudioPressButtonStyle(pressedScale: scale))
    }
}

