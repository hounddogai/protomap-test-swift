import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a specimen metric.
    final class SpecimenMetricView {
        var code: String
        var title: String
        var ownerID: String
        var encounterID: String
        var ratio: String
        var costText: String
        var notes: String
        var startsAt: String
        var visible: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, ownerID: String, encounterID: String, ratio: String, costText: String, notes: String, startsAt: String, visible: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.encounterID = encounterID
            self.ratio = ratio
            self.costText = costText
            self.notes = notes
            self.startsAt = startsAt
            self.visible = visible
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toSpecimenMetricView(_ item: SpecimenMetric) -> SpecimenMetricView {
        return SpecimenMetricView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            ownerID: item.ownerID,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            ratio: String(format: "%.2f", item.ratio),
            costText: String(format: "%.2f", item.cost),
            notes: item.notes,
            startsAt: String(item.startsAt),
            visible: "\(item.visible)",
            label: Kit.Text.truncate(item.label, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSpecimenMetricViews(_ items: [SpecimenMetric]) -> [SpecimenMetricView] {
        var views: [SpecimenMetricView] = []
        for item in items {
            views.append(toSpecimenMetricView(item))
        }
        return views
    }

    static func sumSpecimenMetricView(_ view: SpecimenMetricView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedRatio + parsedCost + Double(parsedStartsAt)
    }
}
