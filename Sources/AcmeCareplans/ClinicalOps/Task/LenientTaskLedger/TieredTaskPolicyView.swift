import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered task policy.
    final class TieredTaskPolicyView {
        var codeText: String
        var title: String
        var externalRef: String
        var score: String
        var costText: String
        var statusLabel: String

        init(codeText: String, title: String, externalRef: String, score: String, costText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.externalRef = externalRef
            self.score = score
            self.costText = costText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredTaskPolicyView(_ item: TieredTaskPolicy) -> TieredTaskPolicyView {
        return TieredTaskPolicyView(
            codeText: item.code,
            title: item.title,
            externalRef: item.externalRef,
            score: String(format: "%.2f", item.score),
            costText: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredTaskPolicyViews(_ items: [TieredTaskPolicy]) -> [TieredTaskPolicyView] {
        var views: [TieredTaskPolicyView] = []
        for item in items {
            views.append(toTieredTaskPolicyView(item))
        }
        return views
    }

    static func sumTieredTaskPolicyView(_ view: TieredTaskPolicyView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedScore + parsedCost
    }
}
