import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling study metric.
    final class RollingStudyMetricView {
        var code: String
        var name: String
        var externalRef: String
        var startsAtText: String
        var unitText: String
        var maximum: String
        var createdAt: String
        var revision: String
        var floorValue: String
        var statusLabel: String

        init(code: String, name: String, externalRef: String, startsAtText: String, unitText: String, maximum: String, createdAt: String, revision: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.startsAtText = startsAtText
            self.unitText = unitText
            self.maximum = maximum
            self.createdAt = createdAt
            self.revision = revision
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toRollingStudyMetricView(_ item: RollingStudyMetric) -> RollingStudyMetricView {
        return RollingStudyMetricView(
            code: item.code,
            name: item.name,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            startsAtText: String(item.startsAt),
            unitText: item.unit,
            maximum: String(format: "%.2f", item.maximum),
            createdAt: String(item.createdAt),
            revision: String(item.revision),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingStudyMetricViews(_ items: [RollingStudyMetric]) -> [RollingStudyMetricView] {
        var views: [RollingStudyMetricView] = []
        for item in items {
            views.append(toRollingStudyMetricView(item))
        }
        return views
    }

    static func sumRollingStudyMetricView(_ view: RollingStudyMetricView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedStartsAt) + parsedMaximum + Double(parsedCreatedAt)
    }
}
