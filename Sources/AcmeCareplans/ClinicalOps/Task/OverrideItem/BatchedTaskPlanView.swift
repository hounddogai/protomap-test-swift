import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a batched task plan.
    final class BatchedTaskPlanView {
        var codeText: String
        var labelText: String
        var ratioText: String
        var weight: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, labelText: String, ratioText: String, weight: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.ratioText = ratioText
            self.weight = weight
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedTaskPlanView(_ item: BatchedTaskPlan) -> BatchedTaskPlanView {
        return BatchedTaskPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            ratioText: String(format: "%.2f", item.ratio),
            weight: String(format: "%.2f", item.weight),
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedTaskPlanViews(_ items: [BatchedTaskPlan]) -> [BatchedTaskPlanView] {
        var views: [BatchedTaskPlanView] = []
        for item in items {
            views.append(toBatchedTaskPlanView(item))
        }
        return views
    }

    static func sumBatchedTaskPlanView(_ view: BatchedTaskPlanView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRatio + parsedWeight
    }
}
