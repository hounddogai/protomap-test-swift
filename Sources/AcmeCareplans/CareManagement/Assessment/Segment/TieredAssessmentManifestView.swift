import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered assessment manifest.
    final class TieredAssessmentManifestView {
        var code: String
        var title: String
        var label: String
        var patientRef: String
        var amountText: String
        var priority: String
        var threshold: String
        var refills: String
        var attempts: String
        var notes: String
        var statusLabel: String

        init(code: String, title: String, label: String, patientRef: String, amountText: String, priority: String, threshold: String, refills: String, attempts: String, notes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.label = label
            self.patientRef = patientRef
            self.amountText = amountText
            self.priority = priority
            self.threshold = threshold
            self.refills = refills
            self.attempts = attempts
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toTieredAssessmentManifestView(_ item: TieredAssessmentManifest) -> TieredAssessmentManifestView {
        return TieredAssessmentManifestView(
            code: item.code,
            title: item.title,
            label: item.label,
            patientRef: item.patientRef,
            amountText: String(format: "%.2f", item.amount),
            priority: String(item.priority),
            threshold: String(format: "%.2f", item.threshold),
            refills: String(item.refills),
            attempts: String(item.attempts),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredAssessmentManifestViews(_ items: [TieredAssessmentManifest]) -> [TieredAssessmentManifestView] {
        var views: [TieredAssessmentManifestView] = []
        for item in items {
            views.append(toTieredAssessmentManifestView(item))
        }
        return views
    }

    static func sumTieredAssessmentManifestView(_ view: TieredAssessmentManifestView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedAmount + Double(parsedPriority) + parsedThreshold
    }
}
