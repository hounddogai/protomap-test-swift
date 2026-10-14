import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched assessment baseline.
    final class BatchedAssessmentBaselineView {
        var code: String
        var label: String
        var capacity: String
        var unitText: String
        var contactEmailText: String
        var retriesText: String
        var acuityText: String
        var revision: String
        var weight: String
        var expiresAt: String
        var payer: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, unitText: String, contactEmailText: String, retriesText: String, acuityText: String, revision: String, weight: String, expiresAt: String, payer: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.unitText = unitText
            self.contactEmailText = contactEmailText
            self.retriesText = retriesText
            self.acuityText = acuityText
            self.revision = revision
            self.weight = weight
            self.expiresAt = expiresAt
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAssessmentBaselineView(_ item: BatchedAssessmentBaseline) -> BatchedAssessmentBaselineView {
        return BatchedAssessmentBaselineView(
            code: item.code,
            label: item.label,
            capacity: String(item.capacity),
            unitText: item.unit,
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 40),
            retriesText: String(item.retries),
            acuityText: String(item.acuity),
            revision: String(item.revision),
            weight: String(format: "%.2f", item.weight),
            expiresAt: String(item.expiresAt),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAssessmentBaselineViews(_ items: [BatchedAssessmentBaseline]) -> [BatchedAssessmentBaselineView] {
        var views: [BatchedAssessmentBaselineView] = []
        for item in items {
            views.append(toBatchedAssessmentBaselineView(item))
        }
        return views
    }

    static func sumBatchedAssessmentBaselineView(_ view: BatchedAssessmentBaselineView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedCapacity) + Double(parsedRetries) + Double(parsedAcuity)
    }
}
