import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal request.
    final class GoalRequestView {
        var code: String
        var label: String
        var region: String
        var batchSize: String
        var summary: String
        var statusLabel: String

        init(code: String, label: String, region: String, batchSize: String, summary: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.region = region
            self.batchSize = batchSize
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toGoalRequestView(_ item: GoalRequest) -> GoalRequestView {
        return GoalRequestView(
            code: item.code,
            label: item.label,
            region: Kit.Text.truncate(item.region, limit: 64),
            batchSize: String(item.batchSize),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalRequestViews(_ items: [GoalRequest]) -> [GoalRequestView] {
        var views: [GoalRequestView] = []
        for item in items {
            views.append(toGoalRequestView(item))
        }
        return views
    }

    static func sumGoalRequestView(_ view: GoalRequestView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedBatchSize)
    }
}
