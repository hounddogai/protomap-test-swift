import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback slot milestone.
    final class FallbackSlotMilestoneView {
        var code: String
        var name: String
        var timezoneText: String
        var cost: String
        var ceilingText: String
        var country: String
        var startsAtText: String
        var contactEmail: String
        var dosageMg: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, name: String, timezoneText: String, cost: String, ceilingText: String, country: String, startsAtText: String, contactEmail: String, dosageMg: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezoneText = timezoneText
            self.cost = cost
            self.ceilingText = ceilingText
            self.country = country
            self.startsAtText = startsAtText
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSlotMilestoneView(_ item: FallbackSlotMilestone) -> FallbackSlotMilestoneView {
        return FallbackSlotMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 80),
            cost: String(format: "%.2f", item.cost),
            ceilingText: String(format: "%.2f", item.ceiling),
            country: item.country,
            startsAtText: String(item.startsAt),
            contactEmail: item.contactEmail,
            dosageMg: String(format: "%.2f", item.dosageMg),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSlotMilestoneViews(_ items: [FallbackSlotMilestone]) -> [FallbackSlotMilestoneView] {
        var views: [FallbackSlotMilestoneView] = []
        for item in items {
            views.append(toFallbackSlotMilestoneView(item))
        }
        return views
    }

    static func sumFallbackSlotMilestoneView(_ view: FallbackSlotMilestoneView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedCost + parsedCeiling + Double(parsedStartsAt)
    }
}
