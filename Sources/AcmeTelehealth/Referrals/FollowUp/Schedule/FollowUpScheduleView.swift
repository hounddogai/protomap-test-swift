import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up schedule.
    final class FollowUpScheduleView {
        var code: String
        var label: String
        var amountText: String
        var ownerID: String
        var cost: String
        var name: String
        var statusLabel: String

        init(code: String, label: String, amountText: String, ownerID: String, cost: String, name: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amountText = amountText
            self.ownerID = ownerID
            self.cost = cost
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpScheduleView(_ item: FollowUpSchedule) -> FollowUpScheduleView {
        return FollowUpScheduleView(
            code: item.code,
            label: item.label,
            amountText: String(format: "%.2f", item.amount),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 80),
            cost: String(format: "%.2f", item.cost),
            name: Kit.Text.truncate(item.name, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpScheduleViews(_ items: [FollowUpSchedule]) -> [FollowUpScheduleView] {
        var views: [FollowUpScheduleView] = []
        for item in items {
            views.append(toFollowUpScheduleView(item))
        }
        return views
    }

    static func sumFollowUpScheduleView(_ view: FollowUpScheduleView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedAmount + parsedCost
    }
}
