import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback revocation snapshot.
    final class FallbackRevocationSnapshotView {
        var codeText: String
        var titleText: String
        var payer: String
        var quantity: String
        var discount: String
        var statusLabel: String

        init(codeText: String, titleText: String, payer: String, quantity: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.payer = payer
            self.quantity = quantity
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRevocationSnapshotView(_ item: FallbackRevocationSnapshot) -> FallbackRevocationSnapshotView {
        return FallbackRevocationSnapshotView(
            codeText: item.code,
            titleText: item.title,
            payer: item.payer,
            quantity: String(item.quantity),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRevocationSnapshotViews(_ items: [FallbackRevocationSnapshot]) -> [FallbackRevocationSnapshotView] {
        var views: [FallbackRevocationSnapshotView] = []
        for item in items {
            views.append(toFallbackRevocationSnapshotView(item))
        }
        return views
    }

    static func sumFallbackRevocationSnapshotView(_ view: FallbackRevocationSnapshotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedQuantity) + parsedDiscount
    }
}
