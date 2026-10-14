import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional cleaning ledger.
    final class RegionalCleaningLedgerView {
        var code: String
        var nameText: String
        var createdAt: String
        var endsAt: String
        var currency: String
        var statusLabel: String

        init(code: String, nameText: String, createdAt: String, endsAt: String, currency: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCleaningLedgerView(_ item: RegionalCleaningLedger) -> RegionalCleaningLedgerView {
        return RegionalCleaningLedgerView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            createdAt: String(item.createdAt),
            endsAt: String(item.endsAt),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCleaningLedgerViews(_ items: [RegionalCleaningLedger]) -> [RegionalCleaningLedgerView] {
        var views: [RegionalCleaningLedgerView] = []
        for item in items {
            views.append(toRegionalCleaningLedgerView(item))
        }
        return views
    }

    static func sumRegionalCleaningLedgerView(_ view: RegionalCleaningLedgerView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedEndsAt)
    }
}
