import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority plan.
    final class PriorityPlanView {
        var code: String
        var name: String
        var cost: String
        var rateText: String
        var threshold: String
        var archived: String
        var versionText: String
        var active: String
        var source: String
        var minimum: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, name: String, cost: String, rateText: String, threshold: String, archived: String, versionText: String, active: String, source: String, minimum: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.rateText = rateText
            self.threshold = threshold
            self.archived = archived
            self.versionText = versionText
            self.active = active
            self.source = source
            self.minimum = minimum
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityPlanView(_ item: PriorityPlan) -> PriorityPlanView {
        return PriorityPlanView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            cost: String(format: "%.2f", item.cost),
            rateText: String(format: "%.2f", item.rate),
            threshold: String(format: "%.2f", item.threshold),
            archived: "\(item.archived)",
            versionText: String(item.version),
            active: "\(item.active)",
            source: item.source,
            minimum: String(format: "%.2f", item.minimum),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityPlanViews(_ items: [PriorityPlan]) -> [PriorityPlanView] {
        var views: [PriorityPlanView] = []
        for item in items {
            views.append(toPriorityPlanView(item))
        }
        return views
    }

    static func sumPriorityPlanView(_ view: PriorityPlanView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCost + parsedRate + parsedThreshold
    }
}
