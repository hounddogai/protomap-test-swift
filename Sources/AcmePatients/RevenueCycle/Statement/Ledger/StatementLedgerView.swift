import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a statement ledger.
    final class StatementLedgerView {
        var code: String
        var label: String
        var channel: String
        var maximum: String
        var timezone: String
        var procedureCode: String
        var source: String
        var name: String
        var statusLabel: String

        init(code: String, label: String, channel: String, maximum: String, timezone: String, procedureCode: String, source: String, name: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.maximum = maximum
            self.timezone = timezone
            self.procedureCode = procedureCode
            self.source = source
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toStatementLedgerView(_ item: StatementLedger) -> StatementLedgerView {
        return StatementLedgerView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            channel: Kit.Text.truncate(item.channel, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            timezone: item.timezone,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            source: item.source,
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStatementLedgerViews(_ items: [StatementLedger]) -> [StatementLedgerView] {
        var views: [StatementLedgerView] = []
        for item in items {
            views.append(toStatementLedgerView(item))
        }
        return views
    }

    static func sumStatementLedgerView(_ view: StatementLedgerView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
