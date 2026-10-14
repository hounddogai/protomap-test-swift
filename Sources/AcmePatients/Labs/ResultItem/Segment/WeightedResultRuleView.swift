import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted result rule.
    final class WeightedResultRuleView {
        var codeText: String
        var name: String
        var batchSizeText: String
        var rate: String
        var startsAtText: String
        var ceiling: String
        var acuityText: String
        var revision: String
        var title: String
        var statusLabel: String

        init(codeText: String, name: String, batchSizeText: String, rate: String, startsAtText: String, ceiling: String, acuityText: String, revision: String, title: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.batchSizeText = batchSizeText
            self.rate = rate
            self.startsAtText = startsAtText
            self.ceiling = ceiling
            self.acuityText = acuityText
            self.revision = revision
            self.title = title
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedResultRuleView(_ item: WeightedResultRule) -> WeightedResultRuleView {
        return WeightedResultRuleView(
            codeText: item.code,
            name: item.name,
            batchSizeText: String(item.batchSize),
            rate: String(format: "%.2f", item.rate),
            startsAtText: String(item.startsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            acuityText: String(item.acuity),
            revision: String(item.revision),
            title: item.title,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedResultRuleViews(_ items: [WeightedResultRule]) -> [WeightedResultRuleView] {
        var views: [WeightedResultRuleView] = []
        for item in items {
            views.append(toWeightedResultRuleView(item))
        }
        return views
    }

    static func sumWeightedResultRuleView(_ view: WeightedResultRuleView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedBatchSize) + parsedRate + Double(parsedStartsAt)
    }
}
