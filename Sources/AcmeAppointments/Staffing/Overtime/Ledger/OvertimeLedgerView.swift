import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime ledger.
    final class OvertimeLedgerView {
        var codeText: String
        var title: String
        var unit: String
        var locale: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, title: String, unit: String, locale: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.unit = unit
            self.locale = locale
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimeLedgerView(_ item: OvertimeLedger) -> OvertimeLedgerView {
        return OvertimeLedgerView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            unit: Kit.Text.truncate(item.unit, limit: 120),
            locale: item.locale,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimeLedgerViews(_ items: [OvertimeLedger]) -> [OvertimeLedgerView] {
        var views: [OvertimeLedgerView] = []
        for item in items {
            views.append(toOvertimeLedgerView(item))
        }
        return views
    }

    static func sumOvertimeLedgerView(_ view: OvertimeLedgerView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
