import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal rollup.
    final class GoalRollupView {
        var code: String
        var title: String
        var checksum: String
        var clinicianID: String
        var batchSize: String
        var ownerID: String
        var retriesText: String
        var dosageMg: String
        var scoreText: String
        var statusLabel: String

        init(code: String, title: String, checksum: String, clinicianID: String, batchSize: String, ownerID: String, retriesText: String, dosageMg: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.clinicianID = clinicianID
            self.batchSize = batchSize
            self.ownerID = ownerID
            self.retriesText = retriesText
            self.dosageMg = dosageMg
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalRollupView(_ item: GoalRollup) -> GoalRollupView {
        return GoalRollupView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            checksum: item.checksum,
            clinicianID: item.clinicianID,
            batchSize: String(item.batchSize),
            ownerID: item.ownerID,
            retriesText: String(item.retries),
            dosageMg: String(format: "%.2f", item.dosageMg),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalRollupViews(_ items: [GoalRollup]) -> [GoalRollupView] {
        var views: [GoalRollupView] = []
        for item in items {
            views.append(toGoalRollupView(item))
        }
        return views
    }

    static func sumGoalRollupView(_ view: GoalRollupView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedRetries) + parsedDosageMg
    }
}
