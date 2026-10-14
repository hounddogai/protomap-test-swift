import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global panel adjustment.
    final class GlobalPanelAdjustmentView {
        var code: String
        var title: String
        var reviewer: String
        var acuity: String
        var maximum: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, acuity: String, maximum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.acuity = acuity
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalPanelAdjustmentView(_ item: GlobalPanelAdjustment) -> GlobalPanelAdjustmentView {
        return GlobalPanelAdjustmentView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            reviewer: item.reviewer,
            acuity: String(item.acuity),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalPanelAdjustmentViews(_ items: [GlobalPanelAdjustment]) -> [GlobalPanelAdjustmentView] {
        var views: [GlobalPanelAdjustmentView] = []
        for item in items {
            views.append(toGlobalPanelAdjustmentView(item))
        }
        return views
    }

    static func sumGlobalPanelAdjustmentView(_ view: GlobalPanelAdjustmentView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedAcuity) + parsedMaximum
    }
}
