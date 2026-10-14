import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending recall template.
    final class PendingRecallTemplateView {
        var code: String
        var title: String
        var cost: String
        var channelText: String
        var ceiling: String
        var threshold: String
        var statusLabel: String

        init(code: String, title: String, cost: String, channelText: String, ceiling: String, threshold: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.channelText = channelText
            self.ceiling = ceiling
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toPendingRecallTemplateView(_ item: PendingRecallTemplate) -> PendingRecallTemplateView {
        return PendingRecallTemplateView(
            code: item.code,
            title: item.title,
            cost: String(format: "%.2f", item.cost),
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            ceiling: String(format: "%.2f", item.ceiling),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingRecallTemplateViews(_ items: [PendingRecallTemplate]) -> [PendingRecallTemplateView] {
        var views: [PendingRecallTemplateView] = []
        for item in items {
            views.append(toPendingRecallTemplateView(item))
        }
        return views
    }

    static func sumPendingRecallTemplateView(_ view: PendingRecallTemplateView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCost + parsedCeiling + parsedThreshold
    }
}
