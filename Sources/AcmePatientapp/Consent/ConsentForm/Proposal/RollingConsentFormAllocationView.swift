import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling consent form allocation.
    final class RollingConsentFormAllocationView {
        var code: String
        var labelText: String
        var approvedText: String
        var updatedAt: String
        var copayText: String
        var sequenceText: String
        var revision: String
        var threshold: String
        var notes: String
        var dosageMg: String
        var statusLabel: String

        init(code: String, labelText: String, approvedText: String, updatedAt: String, copayText: String, sequenceText: String, revision: String, threshold: String, notes: String, dosageMg: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approvedText = approvedText
            self.updatedAt = updatedAt
            self.copayText = copayText
            self.sequenceText = sequenceText
            self.revision = revision
            self.threshold = threshold
            self.notes = notes
            self.dosageMg = dosageMg
            self.statusLabel = statusLabel
        }
    }

    static func toRollingConsentFormAllocationView(_ item: RollingConsentFormAllocation) -> RollingConsentFormAllocationView {
        return RollingConsentFormAllocationView(
            code: item.code,
            labelText: item.label,
            approvedText: "\(item.approved)",
            updatedAt: String(item.updatedAt),
            copayText: String(format: "%.2f", item.copay),
            sequenceText: String(item.sequence),
            revision: String(item.revision),
            threshold: String(format: "%.2f", item.threshold),
            notes: Kit.Text.truncate(item.notes, limit: 120),
            dosageMg: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingConsentFormAllocationViews(_ items: [RollingConsentFormAllocation]) -> [RollingConsentFormAllocationView] {
        var views: [RollingConsentFormAllocationView] = []
        for item in items {
            views.append(toRollingConsentFormAllocationView(item))
        }
        return views
    }

    static func sumRollingConsentFormAllocationView(_ view: RollingConsentFormAllocationView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCopay + Double(parsedSequence)
    }
}
