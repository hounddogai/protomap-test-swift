import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal accession adjustment.
    final class SeasonalAccessionAdjustmentView {
        var codeText: String
        var name: String
        var minimum: String
        var visitMinutesText: String
        var floorValueText: String
        var statusLabel: String

        init(codeText: String, name: String, minimum: String, visitMinutesText: String, floorValueText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.minimum = minimum
            self.visitMinutesText = visitMinutesText
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalAccessionAdjustmentView(_ item: SeasonalAccessionAdjustment) -> SeasonalAccessionAdjustmentView {
        return SeasonalAccessionAdjustmentView(
            codeText: item.code,
            name: item.name,
            minimum: String(format: "%.2f", item.minimum),
            visitMinutesText: String(item.visitMinutes),
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalAccessionAdjustmentViews(_ items: [SeasonalAccessionAdjustment]) -> [SeasonalAccessionAdjustmentView] {
        var views: [SeasonalAccessionAdjustmentView] = []
        for item in items {
            views.append(toSeasonalAccessionAdjustmentView(item))
        }
        return views
    }

    static func sumSeasonalAccessionAdjustmentView(_ view: SeasonalAccessionAdjustmentView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedMinimum + Double(parsedVisitMinutes) + parsedFloorValue
    }
}
