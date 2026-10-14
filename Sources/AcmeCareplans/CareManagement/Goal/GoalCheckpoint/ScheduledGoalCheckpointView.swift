import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a scheduled goal checkpoint.
    final class ScheduledGoalCheckpointView {
        var code: String
        var title: String
        var description: String
        var retriesText: String
        var sequenceText: String
        var rateText: String
        var budgetText: String
        var ratioText: String
        var timezone: String
        var notes: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, title: String, description: String, retriesText: String, sequenceText: String, rateText: String, budgetText: String, ratioText: String, timezone: String, notes: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.retriesText = retriesText
            self.sequenceText = sequenceText
            self.rateText = rateText
            self.budgetText = budgetText
            self.ratioText = ratioText
            self.timezone = timezone
            self.notes = notes
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledGoalCheckpointView(_ item: ScheduledGoalCheckpoint) -> ScheduledGoalCheckpointView {
        return ScheduledGoalCheckpointView(
            code: item.code,
            title: item.title,
            description: item.description,
            retriesText: String(item.retries),
            sequenceText: String(item.sequence),
            rateText: String(format: "%.2f", item.rate),
            budgetText: String(format: "%.2f", item.budget),
            ratioText: String(format: "%.2f", item.ratio),
            timezone: item.timezone,
            notes: item.notes,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledGoalCheckpointViews(_ items: [ScheduledGoalCheckpoint]) -> [ScheduledGoalCheckpointView] {
        var views: [ScheduledGoalCheckpointView] = []
        for item in items {
            views.append(toScheduledGoalCheckpointView(item))
        }
        return views
    }

    static func sumScheduledGoalCheckpointView(_ view: ScheduledGoalCheckpointView) throws -> Double {
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRetries) + Double(parsedSequence) + parsedRate
    }
}
