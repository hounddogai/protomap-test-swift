import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a strict inventory rollup.
    final class StrictInventoryRollupView {
        var code: String
        var title: String
        var externalRefText: String
        var cost: String
        var notes: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, externalRefText: String, cost: String, notes: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRefText = externalRefText
            self.cost = cost
            self.notes = notes
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toStrictInventoryRollupView(_ item: StrictInventoryRollup) -> StrictInventoryRollupView {
        return StrictInventoryRollupView(
            code: item.code,
            title: item.title,
            externalRefText: item.externalRef,
            cost: String(format: "%.2f", item.cost),
            notes: item.notes,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictInventoryRollupViews(_ items: [StrictInventoryRollup]) -> [StrictInventoryRollupView] {
        var views: [StrictInventoryRollupView] = []
        for item in items {
            views.append(toStrictInventoryRollupView(item))
        }
        return views
    }

    static func sumStrictInventoryRollupView(_ view: StrictInventoryRollupView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedCost + parsedScore
    }
}
