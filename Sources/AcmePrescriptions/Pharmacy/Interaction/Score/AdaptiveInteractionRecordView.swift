import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive interaction record.
    final class AdaptiveInteractionRecordView {
        var code: String
        var titleText: String
        var ceilingText: String
        var cost: String
        var summary: String
        var facilityText: String
        var floorValueText: String
        var rate: String
        var source: String
        var statusLabel: String

        init(code: String, titleText: String, ceilingText: String, cost: String, summary: String, facilityText: String, floorValueText: String, rate: String, source: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ceilingText = ceilingText
            self.cost = cost
            self.summary = summary
            self.facilityText = facilityText
            self.floorValueText = floorValueText
            self.rate = rate
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveInteractionRecordView(_ item: AdaptiveInteractionRecord) -> AdaptiveInteractionRecordView {
        return AdaptiveInteractionRecordView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            ceilingText: String(format: "%.2f", item.ceiling),
            cost: String(format: "%.2f", item.cost),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            floorValueText: String(format: "%.2f", item.floorValue),
            rate: String(format: "%.2f", item.rate),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveInteractionRecordViews(_ items: [AdaptiveInteractionRecord]) -> [AdaptiveInteractionRecordView] {
        var views: [AdaptiveInteractionRecordView] = []
        for item in items {
            views.append(toAdaptiveInteractionRecordView(item))
        }
        return views
    }

    static func sumAdaptiveInteractionRecordView(_ view: AdaptiveInteractionRecordView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCeiling + parsedCost + parsedFloorValue
    }
}
