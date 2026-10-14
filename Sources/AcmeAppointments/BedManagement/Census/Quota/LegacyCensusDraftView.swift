import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy census draft.
    final class LegacyCensusDraftView {
        var code: String
        var label: String
        var visible: String
        var budgetText: String
        var reviewer: String
        var channel: String
        var threshold: String
        var batchSizeText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, visible: String, budgetText: String, reviewer: String, channel: String, threshold: String, batchSizeText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.budgetText = budgetText
            self.reviewer = reviewer
            self.channel = channel
            self.threshold = threshold
            self.batchSizeText = batchSizeText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCensusDraftView(_ item: LegacyCensusDraft) -> LegacyCensusDraftView {
        return LegacyCensusDraftView(
            code: item.code,
            label: item.label,
            visible: "\(item.visible)",
            budgetText: String(format: "%.2f", item.budget),
            reviewer: item.reviewer,
            channel: item.channel,
            threshold: String(format: "%.2f", item.threshold),
            batchSizeText: String(item.batchSize),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCensusDraftViews(_ items: [LegacyCensusDraft]) -> [LegacyCensusDraftView] {
        var views: [LegacyCensusDraftView] = []
        for item in items {
            views.append(toLegacyCensusDraftView(item))
        }
        return views
    }

    static func sumLegacyCensusDraftView(_ view: LegacyCensusDraftView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedBudget + parsedThreshold + Double(parsedBatchSize)
    }
}
