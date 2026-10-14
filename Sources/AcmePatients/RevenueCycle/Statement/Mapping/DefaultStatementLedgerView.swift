import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a default statement ledger.
    final class DefaultStatementLedgerView {
        var codeText: String
        var title: String
        var name: String
        var externalRef: String
        var amountText: String
        var startsAt: String
        var statusLabel: String

        init(codeText: String, title: String, name: String, externalRef: String, amountText: String, startsAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.name = name
            self.externalRef = externalRef
            self.amountText = amountText
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultStatementLedgerView(_ item: DefaultStatementLedger) -> DefaultStatementLedgerView {
        return DefaultStatementLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            name: item.name,
            externalRef: item.externalRef,
            amountText: String(format: "%.2f", item.amount),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultStatementLedgerViews(_ items: [DefaultStatementLedger]) -> [DefaultStatementLedgerView] {
        var views: [DefaultStatementLedgerView] = []
        for item in items {
            views.append(toDefaultStatementLedgerView(item))
        }
        return views
    }

    static func sumDefaultStatementLedgerView(_ view: DefaultStatementLedgerView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedAmount + Double(parsedStartsAt)
    }
}
