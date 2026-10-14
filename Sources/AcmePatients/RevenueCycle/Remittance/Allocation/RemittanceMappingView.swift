import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance mapping.
    final class RemittanceMappingView {
        var code: String
        var titleText: String
        var unit: String
        var summary: String
        var floorValueText: String
        var capacityText: String
        var externalRef: String
        var timezone: String
        var costText: String
        var pinnedText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, titleText: String, unit: String, summary: String, floorValueText: String, capacityText: String, externalRef: String, timezone: String, costText: String, pinnedText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.unit = unit
            self.summary = summary
            self.floorValueText = floorValueText
            self.capacityText = capacityText
            self.externalRef = externalRef
            self.timezone = timezone
            self.costText = costText
            self.pinnedText = pinnedText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceMappingView(_ item: RemittanceMapping) -> RemittanceMappingView {
        return RemittanceMappingView(
            code: item.code,
            titleText: item.title,
            unit: Kit.Text.truncate(item.unit, limit: 64),
            summary: item.summary,
            floorValueText: String(format: "%.2f", item.floorValue),
            capacityText: String(item.capacity),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            timezone: item.timezone,
            costText: String(format: "%.2f", item.cost),
            pinnedText: "\(item.pinned)",
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceMappingViews(_ items: [RemittanceMapping]) -> [RemittanceMappingView] {
        var views: [RemittanceMappingView] = []
        for item in items {
            views.append(toRemittanceMappingView(item))
        }
        return views
    }

    static func sumRemittanceMappingView(_ view: RemittanceMappingView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedFloorValue + Double(parsedCapacity) + parsedCost
    }
}
