import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled authorization metric.
    final class ScheduledAuthorizationMetricView {
        var code: String
        var label: String
        var revision: String
        var bed: String
        var capacity: String
        var weightText: String
        var title: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, label: String, revision: String, bed: String, capacity: String, weightText: String, title: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revision = revision
            self.bed = bed
            self.capacity = capacity
            self.weightText = weightText
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledAuthorizationMetricView(_ item: ScheduledAuthorizationMetric) -> ScheduledAuthorizationMetricView {
        return ScheduledAuthorizationMetricView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            revision: String(item.revision),
            bed: item.bed,
            capacity: String(item.capacity),
            weightText: String(format: "%.2f", item.weight),
            title: Kit.Text.truncate(item.title, limit: 80),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledAuthorizationMetricViews(_ items: [ScheduledAuthorizationMetric]) -> [ScheduledAuthorizationMetricView] {
        var views: [ScheduledAuthorizationMetricView] = []
        for item in items {
            views.append(toScheduledAuthorizationMetricView(item))
        }
        return views
    }

    static func sumScheduledAuthorizationMetricView(_ view: ScheduledAuthorizationMetricView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedRevision) + Double(parsedCapacity) + parsedWeight
    }
}
