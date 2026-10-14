import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary credential ledger.
    final class PrimaryCredentialLedgerView {
        var code: String
        var name: String
        var weightText: String
        var maximum: String
        var minimum: String
        var statusLabel: String

        init(code: String, name: String, weightText: String, maximum: String, minimum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weightText = weightText
            self.maximum = maximum
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCredentialLedgerView(_ item: PrimaryCredentialLedger) -> PrimaryCredentialLedgerView {
        return PrimaryCredentialLedgerView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            maximum: String(format: "%.2f", item.maximum),
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCredentialLedgerViews(_ items: [PrimaryCredentialLedger]) -> [PrimaryCredentialLedgerView] {
        var views: [PrimaryCredentialLedgerView] = []
        for item in items {
            views.append(toPrimaryCredentialLedgerView(item))
        }
        return views
    }

    static func sumPrimaryCredentialLedgerView(_ view: PrimaryCredentialLedgerView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedWeight + parsedMaximum + parsedMinimum
    }
}
