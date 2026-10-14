import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up slot.
    final class FollowUpSlotView {
        var code: String
        var title: String
        var maximum: String
        var refills: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, title: String, maximum: String, refills: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.refills = refills
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpSlotView(_ item: FollowUpSlot) -> FollowUpSlotView {
        return FollowUpSlotView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 80),
            maximum: String(format: "%.2f", item.maximum),
            refills: String(item.refills),
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpSlotViews(_ items: [FollowUpSlot]) -> [FollowUpSlotView] {
        var views: [FollowUpSlotView] = []
        for item in items {
            views.append(toFollowUpSlotView(item))
        }
        return views
    }

    static func sumFollowUpSlotView(_ view: FollowUpSlotView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMaximum + Double(parsedRefills) + Double(parsedGraceDays)
    }
}
