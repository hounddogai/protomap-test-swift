import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a scheduled priority score.
    final class ScheduledPriorityScoreView {
        var code: String
        var label: String
        var createdAt: String
        var cost: String
        var title: String
        var visitMinutes: String
        var weightText: String
        var summaryText: String
        var pinned: String
        var acuity: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, cost: String, title: String, visitMinutes: String, weightText: String, summaryText: String, pinned: String, acuity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.cost = cost
            self.title = title
            self.visitMinutes = visitMinutes
            self.weightText = weightText
            self.summaryText = summaryText
            self.pinned = pinned
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPriorityScoreView(_ item: ScheduledPriorityScore) -> ScheduledPriorityScoreView {
        return ScheduledPriorityScoreView(
            code: item.code,
            label: item.label,
            createdAt: String(item.createdAt),
            cost: String(format: "%.2f", item.cost),
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            weightText: String(format: "%.2f", item.weight),
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            pinned: "\(item.pinned)",
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPriorityScoreViews(_ items: [ScheduledPriorityScore]) -> [ScheduledPriorityScoreView] {
        var views: [ScheduledPriorityScoreView] = []
        for item in items {
            views.append(toScheduledPriorityScoreView(item))
        }
        return views
    }

    static func sumScheduledPriorityScoreView(_ view: ScheduledPriorityScoreView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedCreatedAt) + parsedCost + Double(parsedVisitMinutes)
    }
}
