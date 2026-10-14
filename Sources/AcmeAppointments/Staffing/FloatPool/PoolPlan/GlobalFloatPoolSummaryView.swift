import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global float pool summary.
    final class GlobalFloatPoolSummaryView {
        var code: String
        var title: String
        var batchSizeText: String
        var endsAt: String
        var reviewer: String
        var cost: String
        var ownerIDText: String
        var windowDays: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, batchSizeText: String, endsAt: String, reviewer: String, cost: String, ownerIDText: String, windowDays: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.batchSizeText = batchSizeText
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.cost = cost
            self.ownerIDText = ownerIDText
            self.windowDays = windowDays
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFloatPoolSummaryView(_ item: GlobalFloatPoolSummary) -> GlobalFloatPoolSummaryView {
        return GlobalFloatPoolSummaryView(
            code: item.code,
            title: item.title,
            batchSizeText: String(item.batchSize),
            endsAt: String(item.endsAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            cost: String(format: "%.2f", item.cost),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            windowDays: String(item.windowDays),
            category: Kit.Text.truncate(item.category, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFloatPoolSummaryViews(_ items: [GlobalFloatPoolSummary]) -> [GlobalFloatPoolSummaryView] {
        var views: [GlobalFloatPoolSummaryView] = []
        for item in items {
            views.append(toGlobalFloatPoolSummaryView(item))
        }
        return views
    }

    static func sumGlobalFloatPoolSummaryView(_ view: GlobalFloatPoolSummaryView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedEndsAt) + parsedCost
    }
}
