import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched eligibility score.
    final class BatchedEligibilityScoreView {
        var codeText: String
        var title: String
        var maximum: String
        var batchSizeText: String
        var archivedText: String
        var specialtyText: String
        var statusLabel: String

        init(codeText: String, title: String, maximum: String, batchSizeText: String, archivedText: String, specialtyText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.maximum = maximum
            self.batchSizeText = batchSizeText
            self.archivedText = archivedText
            self.specialtyText = specialtyText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedEligibilityScoreView(_ item: BatchedEligibilityScore) -> BatchedEligibilityScoreView {
        return BatchedEligibilityScoreView(
            codeText: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            batchSizeText: String(item.batchSize),
            archivedText: "\(item.archived)",
            specialtyText: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedEligibilityScoreViews(_ items: [BatchedEligibilityScore]) -> [BatchedEligibilityScoreView] {
        var views: [BatchedEligibilityScoreView] = []
        for item in items {
            views.append(toBatchedEligibilityScoreView(item))
        }
        return views
    }

    static func sumBatchedEligibilityScoreView(_ view: BatchedEligibilityScoreView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedMaximum + Double(parsedBatchSize)
    }
}
