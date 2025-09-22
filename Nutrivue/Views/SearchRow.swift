import SwiftUI

struct SearchRow: View {
    let product: ProductData
    let query: String
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let urlString = product.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.gray.opacity(0.2)
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: 48, height: 48)
                .clipped()
                .cornerRadius(6)
            } else {
                ZStack {
                    Color.gray.opacity(0.15)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }
                .frame(width: 48, height: 48)
                .cornerRadius(6)
            }
            VStack(alignment: .leading, spacing: 4) {
                highlight(text: product.productName ?? "Unknown Food", query: query)
                    .font(.body)
                if let code = product.code, !code.isEmpty {
                    Text(code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
            }
            .buttonStyle(.borderless)
        }
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
