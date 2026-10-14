import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility rollup.
    final class EligibilityRollupView {
        var code: String
        var title: String
        var categoryText: String
        var visible: String
        var floorValue: String
        var nameText: String
        var approved: String
        var attemptsText: String
        var capacity: String
        var facilityText: String
        var statusLabel: String

        init(code: String, title: String, categoryText: String, visible: String, floorValue: String, nameText: String, approved: String, attemptsText: String, capacity: String, facilityText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.categoryText = categoryText
            self.visible = visible
            self.floorValue = floorValue
            self.nameText = nameText
            self.approved = approved
            self.attemptsText = attemptsText
            self.capacity = capacity
            self.facilityText = facilityText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityRollupView(_ item: EligibilityRollup) -> EligibilityRollupView {
        return EligibilityRollupView(
            code: item.code,
            title: item.title,
            categoryText: item.category,
            visible: "\(item.visible)",
            floorValue: String(format: "%.2f", item.floorValue),
            nameText: item.name,
            approved: "\(item.approved)",
            attemptsText: String(item.attempts),
            capacity: String(item.capacity),
            facilityText: Kit.Text.truncate(item.facility, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityRollupViews(_ items: [EligibilityRollup]) -> [EligibilityRollupView] {
        var views: [EligibilityRollupView] = []
        for item in items {
            views.append(toEligibilityRollupView(item))
        }
        return views
    }

    static func sumEligibilityRollupView(_ view: EligibilityRollupView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedFloorValue + Double(parsedAttempts) + Double(parsedCapacity)
    }
}
