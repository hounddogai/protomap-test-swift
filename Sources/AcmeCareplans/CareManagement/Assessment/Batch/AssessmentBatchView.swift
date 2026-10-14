import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a assessment batch.
    final class AssessmentBatchView {
        var codeText: String
        var label: String
        var payer: String
        var nameText: String
        var checksum: String
        var score: String
        var statusLabel: String

        init(codeText: String, label: String, payer: String, nameText: String, checksum: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.payer = payer
            self.nameText = nameText
            self.checksum = checksum
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toAssessmentBatchView(_ item: AssessmentBatch) -> AssessmentBatchView {
        return AssessmentBatchView(
            codeText: item.code,
            label: item.label,
            payer: item.payer,
            nameText: item.name,
            checksum: Kit.Text.truncate(item.checksum, limit: 120),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAssessmentBatchViews(_ items: [AssessmentBatch]) -> [AssessmentBatchView] {
        var views: [AssessmentBatchView] = []
        for item in items {
            views.append(toAssessmentBatchView(item))
        }
        return views
    }

    static func sumAssessmentBatchView(_ view: AssessmentBatchView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
