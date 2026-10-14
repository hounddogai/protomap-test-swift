import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped panel window.
    final class CappedPanelWindowView {
        var code: String
        var titleText: String
        var costText: String
        var ward: String
        var statusLabel: String

        init(code: String, titleText: String, costText: String, ward: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.costText = costText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toCappedPanelWindowView(_ item: CappedPanelWindow) -> CappedPanelWindowView {
        return CappedPanelWindowView(
            code: item.code,
            titleText: item.title,
            costText: String(format: "%.2f", item.cost),
            ward: Kit.Text.truncate(item.ward, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedPanelWindowViews(_ items: [CappedPanelWindow]) -> [CappedPanelWindowView] {
        var views: [CappedPanelWindowView] = []
        for item in items {
            views.append(toCappedPanelWindowView(item))
        }
        return views
    }

    static func sumCappedPanelWindowView(_ view: CappedPanelWindowView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
