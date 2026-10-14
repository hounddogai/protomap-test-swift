import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient substitution rollup.
    final class LenientSubstitutionRollupView {
        var code: String
        var labelText: String
        var source: String
        var summary: String
        var ownerIDText: String
        var floorValueText: String
        var graceDays: String
        var margin: String
        var statusLabel: String

        init(code: String, labelText: String, source: String, summary: String, ownerIDText: String, floorValueText: String, graceDays: String, margin: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.source = source
            self.summary = summary
            self.ownerIDText = ownerIDText
            self.floorValueText = floorValueText
            self.graceDays = graceDays
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toLenientSubstitutionRollupView(_ item: LenientSubstitutionRollup) -> LenientSubstitutionRollupView {
        return LenientSubstitutionRollupView(
            code: item.code,
            labelText: item.label,
            source: item.source,
            summary: item.summary,
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 64),
            floorValueText: String(format: "%.2f", item.floorValue),
            graceDays: String(item.graceDays),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientSubstitutionRollupViews(_ items: [LenientSubstitutionRollup]) -> [LenientSubstitutionRollupView] {
        var views: [LenientSubstitutionRollupView] = []
        for item in items {
            views.append(toLenientSubstitutionRollupView(item))
        }
        return views
    }

    static func sumLenientSubstitutionRollupView(_ view: LenientSubstitutionRollupView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedFloorValue + Double(parsedGraceDays) + parsedMargin
    }
}
