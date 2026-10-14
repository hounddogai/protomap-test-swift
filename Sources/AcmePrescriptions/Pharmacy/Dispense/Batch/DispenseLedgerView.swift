import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense ledger.
    final class DispenseLedgerView {
        var code: String
        var title: String
        var ownerID: String
        var currencyText: String
        var attempts: String
        var limit: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, currencyText: String, attempts: String, limit: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.currencyText = currencyText
            self.attempts = attempts
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseLedgerView(_ item: DispenseLedger) -> DispenseLedgerView {
        return DispenseLedgerView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            ownerID: item.ownerID,
            currencyText: Kit.Text.truncate(item.currency, limit: 80),
            attempts: String(item.attempts),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseLedgerViews(_ items: [DispenseLedger]) -> [DispenseLedgerView] {
        var views: [DispenseLedgerView] = []
        for item in items {
            views.append(toDispenseLedgerView(item))
        }
        return views
    }

    static func sumDispenseLedgerView(_ view: DispenseLedgerView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedAttempts) + Double(parsedLimit)
    }
}
