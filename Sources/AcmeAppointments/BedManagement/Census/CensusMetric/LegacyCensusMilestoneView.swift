import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy census milestone.
    final class LegacyCensusMilestoneView {
        var code: String
        var name: String
        var localeText: String
        var floorValueText: String
        var startsAtText: String
        var endsAt: String
        var category: String
        var budget: String
        var reviewer: String
        var statusLabel: String

        init(code: String, name: String, localeText: String, floorValueText: String, startsAtText: String, endsAt: String, category: String, budget: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.localeText = localeText
            self.floorValueText = floorValueText
            self.startsAtText = startsAtText
            self.endsAt = endsAt
            self.category = category
            self.budget = budget
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyCensusMilestoneView(_ item: LegacyCensusMilestone) -> LegacyCensusMilestoneView {
        return LegacyCensusMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            localeText: Kit.Text.truncate(item.locale, limit: 120),
            floorValueText: String(format: "%.2f", item.floorValue),
            startsAtText: String(item.startsAt),
            endsAt: String(item.endsAt),
            category: Kit.Text.truncate(item.category, limit: 120),
            budget: String(format: "%.2f", item.budget),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyCensusMilestoneViews(_ items: [LegacyCensusMilestone]) -> [LegacyCensusMilestoneView] {
        var views: [LegacyCensusMilestoneView] = []
        for item in items {
            views.append(toLegacyCensusMilestoneView(item))
        }
        return views
    }

    static func sumLegacyCensusMilestoneView(_ view: LegacyCensusMilestoneView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedFloorValue + Double(parsedStartsAt) + Double(parsedEndsAt)
    }
}
