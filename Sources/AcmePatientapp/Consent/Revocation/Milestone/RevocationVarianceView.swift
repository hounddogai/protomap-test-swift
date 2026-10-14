import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation variance.
    final class RevocationVarianceView {
        var code: String
        var label: String
        var checksum: String
        var notes: String
        var category: String
        var country: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, checksum: String, notes: String, category: String, country: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.notes = notes
            self.category = category
            self.country = country
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationVarianceView(_ item: RevocationVariance) -> RevocationVarianceView {
        return RevocationVarianceView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            checksum: item.checksum,
            notes: item.notes,
            category: Kit.Text.truncate(item.category, limit: 120),
            country: item.country,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationVarianceViews(_ items: [RevocationVariance]) -> [RevocationVarianceView] {
        var views: [RevocationVarianceView] = []
        for item in items {
            views.append(toRevocationVarianceView(item))
        }
        return views
    }

    static func sumRevocationVarianceView(_ view: RevocationVarianceView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
