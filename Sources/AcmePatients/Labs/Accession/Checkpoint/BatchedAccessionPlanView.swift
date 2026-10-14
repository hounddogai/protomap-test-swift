import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched accession plan.
    final class BatchedAccessionPlanView {
        var code: String
        var titleText: String
        var ownerID: String
        var description: String
        var timezoneText: String
        var name: String
        var channelText: String
        var procedureCode: String
        var threshold: String
        var statusLabel: String

        init(code: String, titleText: String, ownerID: String, description: String, timezoneText: String, name: String, channelText: String, procedureCode: String, threshold: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerID = ownerID
            self.description = description
            self.timezoneText = timezoneText
            self.name = name
            self.channelText = channelText
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedAccessionPlanView(_ item: BatchedAccessionPlan) -> BatchedAccessionPlanView {
        return BatchedAccessionPlanView(
            code: item.code,
            titleText: item.title,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            description: Kit.Text.truncate(item.description, limit: 80),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 64),
            name: item.name,
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedAccessionPlanViews(_ items: [BatchedAccessionPlan]) -> [BatchedAccessionPlanView] {
        var views: [BatchedAccessionPlanView] = []
        for item in items {
            views.append(toBatchedAccessionPlanView(item))
        }
        return views
    }

    static func sumBatchedAccessionPlanView(_ view: BatchedAccessionPlanView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
