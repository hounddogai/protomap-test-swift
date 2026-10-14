import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default consent form ledger.
    final class DefaultConsentFormLedgerView {
        var codeText: String
        var nameText: String
        var facility: String
        var patientRef: String
        var summary: String
        var categoryText: String
        var durationMinutes: String
        var currency: String
        var threshold: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, nameText: String, facility: String, patientRef: String, summary: String, categoryText: String, durationMinutes: String, currency: String, threshold: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.facility = facility
            self.patientRef = patientRef
            self.summary = summary
            self.categoryText = categoryText
            self.durationMinutes = durationMinutes
            self.currency = currency
            self.threshold = threshold
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultConsentFormLedgerView(_ item: DefaultConsentFormLedger) -> DefaultConsentFormLedgerView {
        return DefaultConsentFormLedgerView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            facility: item.facility,
            patientRef: item.patientRef,
            summary: item.summary,
            categoryText: item.category,
            durationMinutes: String(item.durationMinutes),
            currency: item.currency,
            threshold: String(format: "%.2f", item.threshold),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultConsentFormLedgerViews(_ items: [DefaultConsentFormLedger]) -> [DefaultConsentFormLedgerView] {
        var views: [DefaultConsentFormLedgerView] = []
        for item in items {
            views.append(toDefaultConsentFormLedgerView(item))
        }
        return views
    }

    static func sumDefaultConsentFormLedgerView(_ view: DefaultConsentFormLedgerView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedDurationMinutes) + parsedThreshold
    }
}
