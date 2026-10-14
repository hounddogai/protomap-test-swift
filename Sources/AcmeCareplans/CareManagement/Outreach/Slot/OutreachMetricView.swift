import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a outreach metric.
    final class OutreachMetricView {
        var code: String
        var name: String
        var pinned: String
        var thresholdText: String
        var updatedAt: String
        var ownerID: String
        var statusLabel: String

        init(code: String, name: String, pinned: String, thresholdText: String, updatedAt: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.thresholdText = thresholdText
            self.updatedAt = updatedAt
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toOutreachMetricView(_ item: OutreachMetric) -> OutreachMetricView {
        return OutreachMetricView(
            code: item.code,
            name: item.name,
            pinned: "\(item.pinned)",
            thresholdText: String(format: "%.2f", item.threshold),
            updatedAt: String(item.updatedAt),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOutreachMetricViews(_ items: [OutreachMetric]) -> [OutreachMetricView] {
        var views: [OutreachMetricView] = []
        for item in items {
            views.append(toOutreachMetricView(item))
        }
        return views
    }

    static func sumOutreachMetricView(_ view: OutreachMetricView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedThreshold + Double(parsedUpdatedAt)
    }
}
