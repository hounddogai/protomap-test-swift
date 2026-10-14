import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a rolling slot threshold.
    final class RollingSlotThresholdView {
        var code: String
        var titleText: String
        var maximum: String
        var ratio: String
        var floorValue: String
        var createdAt: String
        var revisionText: String
        var graceDays: String
        var reviewer: String
        var acuity: String
        var capacity: String
        var statusLabel: String

        init(code: String, titleText: String, maximum: String, ratio: String, floorValue: String, createdAt: String, revisionText: String, graceDays: String, reviewer: String, acuity: String, capacity: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.maximum = maximum
            self.ratio = ratio
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.revisionText = revisionText
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.acuity = acuity
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toRollingSlotThresholdView(_ item: RollingSlotThreshold) -> RollingSlotThresholdView {
        return RollingSlotThresholdView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            ratio: String(format: "%.2f", item.ratio),
            floorValue: String(format: "%.2f", item.floorValue),
            createdAt: String(item.createdAt),
            revisionText: String(item.revision),
            graceDays: String(item.graceDays),
            reviewer: item.reviewer,
            acuity: String(item.acuity),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingSlotThresholdViews(_ items: [RollingSlotThreshold]) -> [RollingSlotThresholdView] {
        var views: [RollingSlotThresholdView] = []
        for item in items {
            views.append(toRollingSlotThresholdView(item))
        }
        return views
    }

    static func sumRollingSlotThresholdView(_ view: RollingSlotThresholdView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMaximum + parsedRatio + parsedFloorValue
    }
}
