import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered worklist adjustment.
    final class TieredWorklistAdjustmentView {
        var code: String
        var label: String
        var margin: String
        var specialty: String
        var name: String
        var country: String
        var statusLabel: String

        init(code: String, label: String, margin: String, specialty: String, name: String, country: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.margin = margin
            self.specialty = specialty
            self.name = name
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toTieredWorklistAdjustmentView(_ item: TieredWorklistAdjustment) -> TieredWorklistAdjustmentView {
        return TieredWorklistAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            specialty: Kit.Text.truncate(item.specialty, limit: 40),
            name: item.name,
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredWorklistAdjustmentViews(_ items: [TieredWorklistAdjustment]) -> [TieredWorklistAdjustmentView] {
        var views: [TieredWorklistAdjustmentView] = []
        for item in items {
            views.append(toTieredWorklistAdjustmentView(item))
        }
        return views
    }

    static func sumTieredWorklistAdjustmentView(_ view: TieredWorklistAdjustmentView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
