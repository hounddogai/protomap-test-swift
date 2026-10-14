import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution manifest.
    final class SubstitutionManifestView {
        var code: String
        var title: String
        var discount: String
        var label: String
        var updatedAt: String
        var amount: String
        var ownerID: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, title: String, discount: String, label: String, updatedAt: String, amount: String, ownerID: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.discount = discount
            self.label = label
            self.updatedAt = updatedAt
            self.amount = amount
            self.ownerID = ownerID
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionManifestView(_ item: SubstitutionManifest) -> SubstitutionManifestView {
        return SubstitutionManifestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            discount: String(format: "%.2f", item.discount),
            label: item.label,
            updatedAt: String(item.updatedAt),
            amount: String(format: "%.2f", item.amount),
            ownerID: item.ownerID,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionManifestViews(_ items: [SubstitutionManifest]) -> [SubstitutionManifestView] {
        var views: [SubstitutionManifestView] = []
        for item in items {
            views.append(toSubstitutionManifestView(item))
        }
        return views
    }

    static func sumSubstitutionManifestView(_ view: SubstitutionManifestView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedDiscount + Double(parsedUpdatedAt) + parsedAmount
    }
}
