import SwiftUI

struct SearchRow: View {
    let product: ProductData
    let query: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
            // Product Image
            if let urlString = product.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(DesignSystem.Colors.accent)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        DesignSystem.Colors.adaptiveSurface()
                    @unknown default:
                        DesignSystem.Colors.adaptiveSurface()
                    }
                }
                .frame(width: 56, height: 56)
                .clipped()
                .cornerRadius(DesignSystem.CornerRadius.small)
            } else {
                ZStack {
                    DesignSystem.Colors.adaptiveSurface()
                    Image(systemName: "photo")
                        .foregroundColor(DesignSystem.Colors.adaptiveTertiaryText())
                        .font(.title3)
                }
                .frame(width: 56, height: 56)
                .cornerRadius(DesignSystem.CornerRadius.small)
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                highlight(text: product.productName ?? "Unknown Food", query: query)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.adaptivePrimaryText())
                    .lineLimit(2)
                
                if let code = product.code, !code.isEmpty {
                    Text("Barcode: \(code)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.adaptiveSecondaryText())
                }
            }
            
            Spacer()
            
            // Favorite Button
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(isFavorite ? DesignSystem.Colors.accent : DesignSystem.Colors.adaptiveSecondaryText())
            }
            .buttonStyle(.plain)
        }
        .padding(DesignSystem.Spacing.md)
        .metricCardStyle()
    }
    
    private func highlight(text: String, query: String) -> Text {
        guard !query.isEmpty else { return Text(text) }
        let lowerText = text.lowercased()
        let lowerQuery = query.lowercased()
        if let range = lowerText.range(of: lowerQuery) {
            let start = text[..<range.lowerBound]
            let match = text[range]
            let end = text[range.upperBound...]
            return Text(String(start)) + Text(String(match)).bold() + Text(String(end))
        }
        return Text(text)
    }
}
