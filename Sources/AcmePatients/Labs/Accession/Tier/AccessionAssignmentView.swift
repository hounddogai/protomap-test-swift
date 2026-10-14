import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession assignment.
    final class AccessionAssignmentView {
        var code: String
        var label: String
        var retries: String
        var contactEmailText: String
        var threshold: String
        var graceDays: String
        var source: String
        var currency: String
        var patientRef: String
        var rate: String
        var category: String
        var statusLabel: String

        init(code: String, label: String, retries: String, contactEmailText: String, threshold: String, graceDays: String, source: String, currency: String, patientRef: String, rate: String, category: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.retries = retries
            self.contactEmailText = contactEmailText
            self.threshold = threshold
            self.graceDays = graceDays
            self.source = source
            self.currency = currency
            self.patientRef = patientRef
            self.rate = rate
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionAssignmentView(_ item: AccessionAssignment) -> AccessionAssignmentView {
        return AccessionAssignmentView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            retries: String(item.retries),
            contactEmailText: item.contactEmail,
            threshold: String(format: "%.2f", item.threshold),
            graceDays: String(item.graceDays),
            source: item.source,
            currency: item.currency,
            patientRef: item.patientRef,
            rate: String(format: "%.2f", item.rate),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionAssignmentViews(_ items: [AccessionAssignment]) -> [AccessionAssignmentView] {
        var views: [AccessionAssignmentView] = []
        for item in items {
            views.append(toAccessionAssignmentView(item))
        }
        return views
    }

    static func sumAccessionAssignmentView(_ view: AccessionAssignmentView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRetries) + parsedThreshold + Double(parsedGraceDays)
    }
}
