import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling census ledger.
    final class RollingCensusLedgerView {
        var code: String
        var name: String
        var dosageMg: String
        var localeText: String
        var windowDays: String
        var graceDays: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, dosageMg: String, localeText: String, windowDays: String, graceDays: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.localeText = localeText
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCensusLedgerView(_ item: RollingCensusLedger) -> RollingCensusLedgerView {
        return RollingCensusLedgerView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            localeText: item.locale,
            windowDays: String(item.windowDays),
            graceDays: String(item.graceDays),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCensusLedgerViews(_ items: [RollingCensusLedger]) -> [RollingCensusLedgerView] {
        var views: [RollingCensusLedgerView] = []
        for item in items {
            views.append(toRollingCensusLedgerView(item))
        }
        return views
    }

    static func sumRollingCensusLedgerView(_ view: RollingCensusLedgerView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDosageMg + Double(parsedWindowDays) + Double(parsedGraceDays)
    }
}
