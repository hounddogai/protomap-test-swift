import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form digest.
    final class ConsentFormDigestView {
        var codeText: String
        var name: String
        var category: String
        var pinned: String
        var clinicianIDText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, name: String, category: String, pinned: String, clinicianIDText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.category = category
            self.pinned = pinned
            self.clinicianIDText = clinicianIDText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormDigestView(_ item: ConsentFormDigest) -> ConsentFormDigestView {
        return ConsentFormDigestView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            category: item.category,
            pinned: "\(item.pinned)",
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 80),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormDigestViews(_ items: [ConsentFormDigest]) -> [ConsentFormDigestView] {
        var views: [ConsentFormDigestView] = []
        for item in items {
            views.append(toConsentFormDigestView(item))
        }
        return views
    }

    static func sumConsentFormDigestView(_ view: ConsentFormDigestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
