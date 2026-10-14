import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled claim milestone.
    final class ScheduledClaimMilestoneView {
        var code: String
        var name: String
        var quantity: String
        var durationMinutesText: String
        var sourceText: String
        var unit: String
        var regionText: String
        var statusLabel: String

        init(code: String, name: String, quantity: String, durationMinutesText: String, sourceText: String, unit: String, regionText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.durationMinutesText = durationMinutesText
            self.sourceText = sourceText
            self.unit = unit
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledClaimMilestoneView(_ item: ScheduledClaimMilestone) -> ScheduledClaimMilestoneView {
        return ScheduledClaimMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: Kit.Text.truncate(item.name, limit: 64),
            quantity: String(item.quantity),
            durationMinutesText: String(item.durationMinutes),
            sourceText: item.source,
            unit: item.unit,
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledClaimMilestoneViews(_ items: [ScheduledClaimMilestone]) -> [ScheduledClaimMilestoneView] {
        var views: [ScheduledClaimMilestoneView] = []
        for item in items {
            views.append(toScheduledClaimMilestoneView(item))
        }
        return views
    }

    static func sumScheduledClaimMilestoneView(_ view: ScheduledClaimMilestoneView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedQuantity) + Double(parsedDurationMinutes)
    }
}
