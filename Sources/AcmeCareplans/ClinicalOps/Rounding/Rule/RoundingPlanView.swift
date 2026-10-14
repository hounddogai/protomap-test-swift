import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding plan.
    final class RoundingPlanView {
        var codeText: String
        var title: String
        var ceilingText: String
        var capacity: String
        var summaryText: String
        var country: String
        var archivedText: String
        var statusLabel: String

        init(codeText: String, title: String, ceilingText: String, capacity: String, summaryText: String, country: String, archivedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ceilingText = ceilingText
            self.capacity = capacity
            self.summaryText = summaryText
            self.country = country
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingPlanView(_ item: RoundingPlan) -> RoundingPlanView {
        return RoundingPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            ceilingText: String(format: "%.2f", item.ceiling),
            capacity: String(item.capacity),
            summaryText: Kit.Text.truncate(item.summary, limit: 40),
            country: item.country,
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingPlanViews(_ items: [RoundingPlan]) -> [RoundingPlanView] {
        var views: [RoundingPlanView] = []
        for item in items {
            views.append(toRoundingPlanView(item))
        }
        return views
    }

    static func sumRoundingPlanView(_ view: RoundingPlanView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCeiling + Double(parsedCapacity)
    }
}
