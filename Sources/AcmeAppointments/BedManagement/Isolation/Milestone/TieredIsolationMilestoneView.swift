import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered isolation milestone.
    final class TieredIsolationMilestoneView {
        var code: String
        var name: String
        var region: String
        var floorValueText: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, name: String, region: String, floorValueText: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.region = region
            self.floorValueText = floorValueText
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredIsolationMilestoneView(_ item: TieredIsolationMilestone) -> TieredIsolationMilestoneView {
        return TieredIsolationMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            region: item.region,
            floorValueText: String(format: "%.2f", item.floorValue),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredIsolationMilestoneViews(_ items: [TieredIsolationMilestone]) -> [TieredIsolationMilestoneView] {
        var views: [TieredIsolationMilestoneView] = []
        for item in items {
            views.append(toTieredIsolationMilestoneView(item))
        }
        return views
    }

    static func sumTieredIsolationMilestoneView(_ view: TieredIsolationMilestoneView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedFloorValue + Double(parsedDurationMinutes)
    }
}
