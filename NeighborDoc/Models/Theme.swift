import SwiftUI

struct Theme {
    // Colors
    static let accentColor = Color(red: 0.0, green: 0.76, blue: 0.66) // #00C2A8 teal
    static let accentBlue = Color(red: 0.23, green: 0.53, blue: 1.0) // #3A86FF blue
    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.2)
    static let dropdownBackground = Color(red: 0.11, green: 0.11, blue: 0.12) // #1C1C1E
    static let dividerColor = Color.white.opacity(0.1)
    
    // Typography
    static let doctorNameFont = Font.system(size: 18, weight: .bold)
    static let specialtyFont = Font.system(size: 15, weight: .medium)
    static let locationFont = Font.system(size: 14, weight: .regular)
    static let sectionHeaderFont = Font.system(size: 16, weight: .semibold)
    static let emptyStateFont = Font.system(size: 16, weight: .medium)
    
    // Colors for text - adaptive for light/dark mode
    static let doctorNameColor = Color.primary
    static let specialtyColor = Color.secondary
    static let locationColor = Color.secondary.opacity(0.8)
    static let sectionHeaderColor = Color.secondary
    static let emptyStateColor = Color.secondary
    
    // Spacing
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let listItemPadding: CGFloat = 16
    
    // Corner radius
    static let cornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 20
    
    // Shadows
    static let dropdownShadow = Color.black.opacity(0.2)
    
    static func cardStyle() -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(cardBackground)
            .shadow(color: cardShadow, radius: 4, x: 0, y: 2)
    }
    
    static func dropdownStyle() -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(dropdownBackground)
            .shadow(color: dropdownShadow, radius: 8, x: 0, y: 4)
    }
    
    static func pillButtonStyle() -> some View {
        RoundedRectangle(cornerRadius: buttonCornerRadius)
            .stroke(accentColor, lineWidth: 1)
    }
}
