import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a scheduled task summary.
    final class ScheduledTaskSummaryView {
        var code: String
        var label: String
        var bed: String
        var amount: String
        var facility: String
        var startsAtText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, bed: String, amount: String, facility: String, startsAtText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.bed = bed
            self.amount = amount
            self.facility = facility
            self.startsAtText = startsAtText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledTaskSummaryView(_ item: ScheduledTaskSummary) -> ScheduledTaskSummaryView {
        return ScheduledTaskSummaryView(
            code: item.code,
            label: item.label,
            bed: item.bed,
            amount: String(format: "%.2f", item.amount),
            facility: Kit.Text.truncate(item.facility, limit: 120),
            startsAtText: String(item.startsAt),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledTaskSummaryViews(_ items: [ScheduledTaskSummary]) -> [ScheduledTaskSummaryView] {
        var views: [ScheduledTaskSummaryView] = []
        for item in items {
            views.append(toScheduledTaskSummaryView(item))
        }
        return views
    }

    static func sumScheduledTaskSummaryView(_ view: ScheduledTaskSummaryView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedAmount + Double(parsedStartsAt) + Double(parsedUpdatedAt)
    }
}
