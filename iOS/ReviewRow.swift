import SwiftUI
import Translation

/// One customer review with Reply and, on iOS 17.4 and later, Translate: Apple's own on-device translation sheet.
struct ReviewRow: View {
    let review: Doc<ReviewAttrs>.Item
    var reply: () -> Void
    @State private var translating = false

    var text: String { [review.attributes.title, review.attributes.body].compactMap { $0 }.joined(separator: "\n\n") }

    var body: some View {
        let a = review.attributes
        VStack(alignment: .leading, spacing: 4) {
            Text(String(repeating: "★", count: a.rating ?? 0) + " " + (a.title ?? "")).font(Theme.font(15, .semibold))
            Text(a.body ?? "").font(Theme.font(14)).foregroundStyle(Theme.muted)
            Text("\(a.reviewerNickname ?? "") · \(a.territory ?? "") · \(String((a.createdDate ?? "").prefix(10)))").font(Theme.font(12)).foregroundStyle(Theme.muted)
            HStack(spacing: 16) {
                Button("Reply", systemImage: "arrowshape.turn.up.left", action: reply)
                if #available(iOS 17.4, *) {
                    Button("Translate", systemImage: "translate") { translating = true }
                        .translationPresentation(isPresented: $translating, text: text)
                }
            }
            .font(Theme.font(13, .semibold))
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.accent)
            .padding(.top, 6)
        }
        .foregroundStyle(Theme.text)
    }
}
