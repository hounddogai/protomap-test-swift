import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a batched care protocol plan.
    final class BatchedCareProtocolPlanView {
        var codeText: String
        var label: String
        var channelText: String
        var graceDays: String
        var sequence: String
        var titleText: String
        var rateText: String
        var visible: String
        var statusLabel: String

        init(codeText: String, label: String, channelText: String, graceDays: String, sequence: String, titleText: String, rateText: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.channelText = channelText
            self.graceDays = graceDays
            self.sequence = sequence
            self.titleText = titleText
            self.rateText = rateText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareProtocolPlanView(_ item: BatchedCareProtocolPlan) -> BatchedCareProtocolPlanView {
        return BatchedCareProtocolPlanView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            channelText: item.channel,
            graceDays: String(item.graceDays),
            sequence: String(item.sequence),
            titleText: item.title,
            rateText: String(format: "%.2f", item.rate),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareProtocolPlanViews(_ items: [BatchedCareProtocolPlan]) -> [BatchedCareProtocolPlanView] {
        var views: [BatchedCareProtocolPlanView] = []
        for item in items {
            views.append(toBatchedCareProtocolPlanView(item))
        }
        return views
    }

    static func sumBatchedCareProtocolPlanView(_ view: BatchedCareProtocolPlanView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedSequence) + parsedRate
    }
}
