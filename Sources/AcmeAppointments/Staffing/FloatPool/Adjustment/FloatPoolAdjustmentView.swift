import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool adjustment.
    final class FloatPoolAdjustmentView {
        var code: String
        var labelText: String
        var approved: String
        var notesText: String
        var region: String
        var margin: String
        var statusLabel: String

        init(code: String, labelText: String, approved: String, notesText: String, region: String, margin: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approved = approved
            self.notesText = notesText
            self.region = region
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolAdjustmentView(_ item: FloatPoolAdjustment) -> FloatPoolAdjustmentView {
        return FloatPoolAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            approved: "\(item.approved)",
            notesText: item.notes,
            region: item.region,
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolAdjustmentViews(_ items: [FloatPoolAdjustment]) -> [FloatPoolAdjustmentView] {
        var views: [FloatPoolAdjustmentView] = []
        for item in items {
            views.append(toFloatPoolAdjustmentView(item))
        }
        return views
    }

    static func sumFloatPoolAdjustmentView(_ view: FloatPoolAdjustmentView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMargin
    }
}
