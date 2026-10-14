import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan digest.
    final class DischargePlanDigestView {
        var code: String
        var title: String
        var cost: String
        var summary: String
        var marginText: String
        var floorValue: String
        var minimumText: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, cost: String, summary: String, marginText: String, floorValue: String, minimumText: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.cost = cost
            self.summary = summary
            self.marginText = marginText
            self.floorValue = floorValue
            self.minimumText = minimumText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanDigestView(_ item: DischargePlanDigest) -> DischargePlanDigestView {
        return DischargePlanDigestView(
            code: item.code,
            title: item.title,
            cost: String(format: "%.2f", item.cost),
            summary: item.summary,
            marginText: String(format: "%.2f", item.margin),
            floorValue: String(format: "%.2f", item.floorValue),
            minimumText: String(format: "%.2f", item.minimum),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanDigestViews(_ items: [DischargePlanDigest]) -> [DischargePlanDigestView] {
        var views: [DischargePlanDigestView] = []
        for item in items {
            views.append(toDischargePlanDigestView(item))
        }
        return views
    }

    static func sumDischargePlanDigestView(_ view: DischargePlanDigestView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCost + parsedMargin + parsedFloorValue
    }
}
