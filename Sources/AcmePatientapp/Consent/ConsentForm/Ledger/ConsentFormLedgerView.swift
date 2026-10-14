import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form ledger.
    final class ConsentFormLedgerView {
        var code: String
        var title: String
        var unit: String
        var threshold: String
        var retries: String
        var cost: String
        var minimum: String
        var patientRef: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, unit: String, threshold: String, retries: String, cost: String, minimum: String, patientRef: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.threshold = threshold
            self.retries = retries
            self.cost = cost
            self.minimum = minimum
            self.patientRef = patientRef
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormLedgerView(_ item: ConsentFormLedger) -> ConsentFormLedgerView {
        return ConsentFormLedgerView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            unit: item.unit,
            threshold: String(format: "%.2f", item.threshold),
            retries: String(item.retries),
            cost: String(format: "%.2f", item.cost),
            minimum: String(format: "%.2f", item.minimum),
            patientRef: item.patientRef,
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormLedgerViews(_ items: [ConsentFormLedger]) -> [ConsentFormLedgerView] {
        var views: [ConsentFormLedgerView] = []
        for item in items {
            views.append(toConsentFormLedgerView(item))
        }
        return views
    }

    static func sumConsentFormLedgerView(_ view: ConsentFormLedgerView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedThreshold + Double(parsedRetries) + parsedCost
    }
}
