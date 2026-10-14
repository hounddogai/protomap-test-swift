import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment adjustment.
    final class AssessmentAdjustmentView {
        var codeText: String
        var label: String
        var encounterID: String
        var capacityText: String
        var segment: String
        var rateText: String
        var copay: String
        var retriesText: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, label: String, encounterID: String, capacityText: String, segment: String, rateText: String, copay: String, retriesText: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.encounterID = encounterID
            self.capacityText = capacityText
            self.segment = segment
            self.rateText = rateText
            self.copay = copay
            self.retriesText = retriesText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentAdjustmentView(_ item: AssessmentAdjustment) -> AssessmentAdjustmentView {
        return AssessmentAdjustmentView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            capacityText: String(item.capacity),
            segment: item.segment,
            rateText: String(format: "%.2f", item.rate),
            copay: String(format: "%.2f", item.copay),
            retriesText: String(item.retries),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentAdjustmentViews(_ items: [AssessmentAdjustment]) -> [AssessmentAdjustmentView] {
        var views: [AssessmentAdjustmentView] = []
        for item in items {
            views.append(toAssessmentAdjustmentView(item))
        }
        return views
    }

    static func sumAssessmentAdjustmentView(_ view: AssessmentAdjustmentView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedCapacity) + parsedRate + parsedCopay
    }
}
