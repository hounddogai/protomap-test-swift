import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled reference range record.
    final class ScheduledReferenceRangeRecordView {
        var code: String
        var label: String
        var weightText: String
        var region: String
        var rate: String
        var category: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, label: String, weightText: String, region: String, rate: String, category: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.weightText = weightText
            self.region = region
            self.rate = rate
            self.category = category
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledReferenceRangeRecordView(_ item: ScheduledReferenceRangeRecord) -> ScheduledReferenceRangeRecordView {
        return ScheduledReferenceRangeRecordView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            weightText: String(format: "%.2f", item.weight),
            region: item.region,
            rate: String(format: "%.2f", item.rate),
            category: Kit.Text.truncate(item.category, limit: 120),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledReferenceRangeRecordViews(_ items: [ScheduledReferenceRangeRecord]) -> [ScheduledReferenceRangeRecordView] {
        var views: [ScheduledReferenceRangeRecordView] = []
        for item in items {
            views.append(toScheduledReferenceRangeRecordView(item))
        }
        return views
    }

    static func sumScheduledReferenceRangeRecordView(_ view: ScheduledReferenceRangeRecordView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedWeight + parsedRate + parsedFloorValue
    }
}
