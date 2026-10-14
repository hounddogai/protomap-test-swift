import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range schedule.
    final class ReferenceRangeScheduleView {
        var code: String
        var name: String
        var channel: String
        var checksum: String
        var archived: String
        var budgetText: String
        var statusLabel: String

        init(code: String, name: String, channel: String, checksum: String, archived: String, budgetText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.channel = channel
            self.checksum = checksum
            self.archived = archived
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeScheduleView(_ item: ReferenceRangeSchedule) -> ReferenceRangeScheduleView {
        return ReferenceRangeScheduleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            channel: item.channel,
            checksum: item.checksum,
            archived: "\(item.archived)",
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeScheduleViews(_ items: [ReferenceRangeSchedule]) -> [ReferenceRangeScheduleView] {
        var views: [ReferenceRangeScheduleView] = []
        for item in items {
            views.append(toReferenceRangeScheduleView(item))
        }
        return views
    }

    static func sumReferenceRangeScheduleView(_ view: ReferenceRangeScheduleView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
