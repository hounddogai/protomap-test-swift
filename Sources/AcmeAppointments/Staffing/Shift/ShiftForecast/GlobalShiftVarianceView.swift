import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global shift variance.
    final class GlobalShiftVarianceView {
        var code: String
        var title: String
        var marginText: String
        var sequence: String
        var floorValue: String
        var encounterIDText: String
        var limit: String
        var archived: String
        var unit: String
        var discount: String
        var capacity: String
        var statusLabel: String

        init(code: String, title: String, marginText: String, sequence: String, floorValue: String, encounterIDText: String, limit: String, archived: String, unit: String, discount: String, capacity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.marginText = marginText
            self.sequence = sequence
            self.floorValue = floorValue
            self.encounterIDText = encounterIDText
            self.limit = limit
            self.archived = archived
            self.unit = unit
            self.discount = discount
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalShiftVarianceView(_ item: GlobalShiftVariance) -> GlobalShiftVarianceView {
        return GlobalShiftVarianceView(
            code: item.code,
            title: item.title,
            marginText: String(format: "%.2f", item.margin),
            sequence: String(item.sequence),
            floorValue: String(format: "%.2f", item.floorValue),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 80),
            limit: String(item.limit),
            archived: "\(item.archived)",
            unit: Kit.Text.truncate(item.unit, limit: 40),
            discount: String(format: "%.2f", item.discount),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalShiftVarianceViews(_ items: [GlobalShiftVariance]) -> [GlobalShiftVarianceView] {
        var views: [GlobalShiftVarianceView] = []
        for item in items {
            views.append(toGlobalShiftVarianceView(item))
        }
        return views
    }

    static func sumGlobalShiftVarianceView(_ view: GlobalShiftVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMargin + Double(parsedSequence) + parsedFloorValue
    }
}
