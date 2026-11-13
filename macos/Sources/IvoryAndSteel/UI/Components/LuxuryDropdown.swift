import SwiftUI

// MARK: - Luxury Dropdown Option & Section Models

public struct LuxuryDropdownOption<Value: Hashable & Sendable>: Identifiable, Sendable {
    public let value: Value
    public let title: String
    public let subtitle: String?
    public let badge: String?
    public let section: String?
    
    public var id: Value { value }
    
    public init(
        value: Value,
        title: String,
        subtitle: String? = nil,
        badge: String? = nil,
        section: String? = nil
    ) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.section = section
    }
}

public enum LuxuryDropdownShape: Sendable {
    case capsule
    case rounded(CGFloat)
}

// MARK: - Smooth Apple-Glassmorphism Animated Dropdown

/// Smooth, Apple-craft frosted-glass dropdown popover replacing rigid system NSMenu/NSPopUpButton menus.
/// Features anchored below-trigger positioning (never overlapping the trigger), smooth spring entrance
/// animation, rotating chevron indicator, hover glide highlights, and champagne-gold selection cues.
public struct LuxuryDropdown<Value: Hashable & Sendable, TriggerLabel: View>: View {
    @Binding public var selection: Value
    public let options: [LuxuryDropdownOption<Value>]
    public let popoverWidth: CGFloat
    public let maxPopoverHeight: CGFloat
    public let shape: LuxuryDropdownShape
    public let onSelect: ((Value) -> Void)?
    @ViewBuilder public let label: (_ isOpen: Bool, _ isHovered: Bool) -> TriggerLabel
    
    @State private var isOpen: Bool = false
    @State private var isHovered: Bool = false
    
    public init(
        selection: Binding<Value>,
        options: [LuxuryDropdownOption<Value>],
        popoverWidth: CGFloat = 230,
        maxPopoverHeight: CGFloat = 330,
        shape: LuxuryDropdownShape = .rounded(7),
        onSelect: ((Value) -> Void)? = nil,
        @ViewBuilder label: @escaping (_ isOpen: Bool, _ isHovered: Bool) -> TriggerLabel
    ) {
        self._selection = selection
        self.options = options
        self.popoverWidth = popoverWidth
        self.maxPopoverHeight = maxPopoverHeight
        self.shape = shape
        self.onSelect = onSelect
        self.label = label
    }
    
    public var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                isOpen.toggle()
            }
        }) {
            label(isOpen, isHovered)
                .scaleEffect(isOpen ? 0.985 : 1.0)
                .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isOpen)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.16)) {
                isHovered = hovering
            }
        }
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            LuxuryDropdownPopoverContent(
                selection: $selection,
                options: options,
                width: popoverWidth,
                maxHeight: maxPopoverHeight,
                onSelect: { newValue in
                    selection = newValue
                    onSelect?(newValue)
                    withAnimation(.easeOut(duration: 0.15)) {
                        isOpen = false
                    }
                }
            )
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Convenience Default Trigger Initializer

public extension LuxuryDropdown where TriggerLabel == LuxuryDropdownDefaultLabel {
    init(
        selection: Binding<Value>,
        options: [LuxuryDropdownOption<Value>],
        prefix: String? = nil,
        minWidth: CGFloat? = nil,
        popoverWidth: CGFloat = 230,
        maxPopoverHeight: CGFloat = 330,
        shape: LuxuryDropdownShape = .rounded(7),
        accentColor: Color = .musicianGoldLight,
        onSelect: ((Value) -> Void)? = nil
    ) {
        let selectedTitle = options.first(where: { $0.value == selection.wrappedValue })?.title ?? ""
        self.init(
            selection: selection,
            options: options,
            popoverWidth: popoverWidth,
            maxPopoverHeight: maxPopoverHeight,
            shape: shape,
            onSelect: onSelect
        ) { isOpen, isHovered in
            LuxuryDropdownDefaultLabel(
                prefix: prefix,
                title: selectedTitle,
                isOpen: isOpen,
                isHovered: isHovered,
                shape: shape,
                minWidth: minWidth,
                accentColor: accentColor
            )
        }
    }
}

public struct LuxuryDropdownDefaultLabel: View {
    public let prefix: String?
    public let title: String
    public let isOpen: Bool
    public let isHovered: Bool
    public let shape: LuxuryDropdownShape
    public let minWidth: CGFloat?
    public let accentColor: Color
    
    public var body: some View {
        HStack(spacing: 6) {
            if let prefix, !prefix.isEmpty {
                Text(prefix)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(isOpen ? accentColor : Color.musicianIvory)
                .lineLimit(1)
            
            if minWidth != nil {
                Spacer(minLength: 6)
            }
            
            Image(systemName: "chevron.down")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(isOpen ? Color.musicianGold : Color.white.opacity(0.5))
                .rotationEffect(.degrees(isOpen ? 180 : 0))
                .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isOpen)
        }
        .padding(.horizontal, 10)
        .frame(minWidth: minWidth)
        .frame(height: 28)
        .fixedSize(horizontal: minWidth == nil, vertical: true)
        .background(
            isOpen
                ? Color.white.opacity(0.11)
                : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.05))
        )
        .clipShape(triggerClipShape)
        .overlay(
            triggerStrokeOverlay
        )
    }
    
    private var triggerClipShape: AnyShape {
        switch shape {
        case .capsule: return AnyShape(Capsule())
        case .rounded(let r): return AnyShape(RoundedRectangle(cornerRadius: r))
        }
    }
    
    @ViewBuilder
    private var triggerStrokeOverlay: some View {
        let color = isOpen
            ? Color.musicianGold.opacity(0.65)
            : (isHovered ? Color.white.opacity(0.22) : Color.white.opacity(0.10))
        let width: CGFloat = isOpen ? 1.0 : 0.7
        switch shape {
        case .capsule:
            Capsule().strokeBorder(color, lineWidth: width)
        case .rounded(let r):
            RoundedRectangle(cornerRadius: r).strokeBorder(color, lineWidth: width)
        }
    }
}

// MARK: - Animated Glassmorphism Popover Body

private struct LuxuryDropdownPopoverContent<Value: Hashable & Sendable>: View {
    @Binding var selection: Value
    let options: [LuxuryDropdownOption<Value>]
    let width: CGFloat
    let maxHeight: CGFloat
    let onSelect: (Value) -> Void
    
    @State private var isRevealed: Bool = false
    
    private struct OptionGroup: Identifiable {
        let id: String
        let title: String?
        let items: [LuxuryDropdownOption<Value>]
    }
    
    private var groups: [OptionGroup] {
        var result: [OptionGroup] = []
        var currentTitle: String? = options.first?.section
        var currentItems: [LuxuryDropdownOption<Value>] = []
        
        for opt in options {
            if opt.section != currentTitle && !currentItems.isEmpty {
                result.append(OptionGroup(
                    id: "\(result.count)-\(currentTitle ?? "default")",
                    title: currentTitle,
                    items: currentItems
                ))
                currentTitle = opt.section
                currentItems = [opt]
            } else {
                currentTitle = opt.section
                currentItems.append(opt)
            }
        }
        if !currentItems.isEmpty {
            result.append(OptionGroup(
                id: "\(result.count)-\(currentTitle ?? "default")",
                title: currentTitle,
                items: currentItems
            ))
        }
        return result
    }
    
    private var estimatedHeight: CGFloat {
        let sectionCount = groups.filter { $0.title != nil }.count
        let rowsHeight = CGFloat(options.count) * 32.0
        let headersHeight = CGFloat(sectionCount) * 26.0
        let verticalPadding: CGFloat = 16.0
        return min(maxHeight, max(44.0, rowsHeight + headersHeight + verticalPadding))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: options.count > 8) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(groups) { group in
                        if let title = group.title {
                            Text(title.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .tracking(0.8)
                                .foregroundColor(Color.musicianGold.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.top, group.id.hasPrefix("0-") ? 4 : 8)
                                .padding(.bottom, 3)
                        }
                        
                        ForEach(group.items) { option in
                            LuxuryDropdownOptionRow(
                                option: option,
                                isSelected: option.value == selection,
                                onTap: { onSelect(option.value) }
                            )
                            .id(option.value)
                        }
                    }
                }
                .padding(6)
            }
            .frame(width: width, height: estimatedHeight)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color.musicianEbony.opacity(0.72)
                }
            )
            .preferredColorScheme(.dark)
            .scaleEffect(isRevealed ? 1.0 : 0.95, anchor: .top)
            .opacity(isRevealed ? 1.0 : 0.0)
            .offset(y: isRevealed ? 0 : -5)
            .onAppear {
                withAnimation(.spring(response: 0.26, dampingFraction: 0.84)) {
                    isRevealed = true
                }
                DispatchQueue.main.async {
                    proxy.scrollTo(selection, anchor: .center)
                }
            }
        }
    }
}

private struct LuxuryDropdownOptionRow<Value: Hashable & Sendable>: View {
    let option: LuxuryDropdownOption<Value>
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Smooth indicator dot / check
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color.musicianGold)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .fill(Color.white.opacity(isHovered ? 0.35 : 0.0))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(width: 14)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(option.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? Color.musicianGoldLight : Color.musicianIvory.opacity(isHovered ? 1.0 : 0.88))
                        .lineLimit(1)
                    
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.45))
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 4)
                
                if let badge = option.badge {
                    Text(badge)
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(isSelected ? Color.musicianGold : Color.white.opacity(0.45))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(isSelected ? 0.08 : 0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, option.subtitle == nil ? 5.5 : 6)
            .contentShape(RoundedRectangle(cornerRadius: 7))
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(
                        isSelected
                            ? Color.musicianGold.opacity(0.32)
                            : (isHovered ? Color.white.opacity(0.08) : Color.clear),
                        lineWidth: 0.7
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
    
    private var rowBackground: Color {
        if isSelected {
            return Color.musicianGold.opacity(isHovered ? 0.18 : 0.12)
        }
        return isHovered ? Color.white.opacity(0.08) : Color.clear
    }
}

