import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched assessment estimate.
    final class BatchedAssessmentEstimateView {
        var codeText: String
        var label: String
        var sequence: String
        var active: String
        var amount: String
        var procedureCode: String
        var externalRef: String
        var categoryText: String
        var minimumText: String
        var statusLabel: String

        init(codeText: String, label: String, sequence: String, active: String, amount: String, procedureCode: String, externalRef: String, categoryText: String, minimumText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.sequence = sequence
            self.active = active
            self.amount = amount
            self.procedureCode = procedureCode
            self.externalRef = externalRef
            self.categoryText = categoryText
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAssessmentEstimateView(_ item: BatchedAssessmentEstimate) -> BatchedAssessmentEstimateView {
        return BatchedAssessmentEstimateView(
            codeText: item.code,
            label: item.label,
            sequence: String(item.sequence),
            active: "\(item.active)",
            amount: String(format: "%.2f", item.amount),
            procedureCode: item.procedureCode,
            externalRef: item.externalRef,
            categoryText: item.category,
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAssessmentEstimateViews(_ items: [BatchedAssessmentEstimate]) -> [BatchedAssessmentEstimateView] {
        var views: [BatchedAssessmentEstimateView] = []
        for item in items {
            views.append(toBatchedAssessmentEstimateView(item))
        }
        return views
    }

    static func sumBatchedAssessmentEstimateView(_ view: BatchedAssessmentEstimateView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedSequence) + parsedAmount + parsedMinimum
    }
}
