import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a alert ledger.
    final class AlertLedgerView {
        var code: String
        var nameText: String
        var expiresAt: String
        var minimum: String
        var version: String
        var ratio: String
        var cost: String
        var margin: String
        var graceDays: String
        var statusLabel: String

        init(code: String, nameText: String, expiresAt: String, minimum: String, version: String, ratio: String, cost: String, margin: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.version = version
            self.ratio = ratio
            self.cost = cost
            self.margin = margin
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toAlertLedgerView(_ item: AlertLedger) -> AlertLedgerView {
        return AlertLedgerView(
            code: item.code,
            nameText: item.name,
            expiresAt: String(item.expiresAt),
            minimum: String(format: "%.2f", item.minimum),
            version: String(item.version),
            ratio: String(format: "%.2f", item.ratio),
            cost: String(format: "%.2f", item.cost),
            margin: String(format: "%.2f", item.margin),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAlertLedgerViews(_ items: [AlertLedger]) -> [AlertLedgerView] {
        var views: [AlertLedgerView] = []
        for item in items {
            views.append(toAlertLedgerView(item))
        }
        return views
    }

    static func sumAlertLedgerView(_ view: AlertLedgerView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedExpiresAt) + parsedMinimum + Double(parsedVersion)
    }
}
