import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy specimen metric.
    final class LegacySpecimenMetricView {
        var code: String
        var name: String
        var acuityText: String
        var regionText: String
        var reviewerText: String
        var capacity: String
        var facility: String
        var priorityText: String
        var labelText: String
        var statusLabel: String

        init(code: String, name: String, acuityText: String, regionText: String, reviewerText: String, capacity: String, facility: String, priorityText: String, labelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuityText = acuityText
            self.regionText = regionText
            self.reviewerText = reviewerText
            self.capacity = capacity
            self.facility = facility
            self.priorityText = priorityText
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySpecimenMetricView(_ item: LegacySpecimenMetric) -> LegacySpecimenMetricView {
        return LegacySpecimenMetricView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            acuityText: String(item.acuity),
            regionText: item.region,
            reviewerText: item.reviewer,
            capacity: String(item.capacity),
            facility: item.facility,
            priorityText: String(item.priority),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySpecimenMetricViews(_ items: [LegacySpecimenMetric]) -> [LegacySpecimenMetricView] {
        var views: [LegacySpecimenMetricView] = []
        for item in items {
            views.append(toLegacySpecimenMetricView(item))
        }
        return views
    }

    static func sumLegacySpecimenMetricView(_ view: LegacySpecimenMetricView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedAcuity) + Double(parsedCapacity) + Double(parsedPriority)
    }
}
