import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation mapping.
    final class IsolationMappingView {
        var codeText: String
        var title: String
        var weightText: String
        var costText: String
        var margin: String
        var pinned: String
        var copayText: String
        var discount: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, title: String, weightText: String, costText: String, margin: String, pinned: String, copayText: String, discount: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.weightText = weightText
            self.costText = costText
            self.margin = margin
            self.pinned = pinned
            self.copayText = copayText
            self.discount = discount
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationMappingView(_ item: IsolationMapping) -> IsolationMappingView {
        return IsolationMappingView(
            codeText: item.code,
            title: item.title,
            weightText: String(format: "%.2f", item.weight),
            costText: String(format: "%.2f", item.cost),
            margin: String(format: "%.2f", item.margin),
            pinned: "\(item.pinned)",
            copayText: String(format: "%.2f", item.copay),
            discount: String(format: "%.2f", item.discount),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationMappingViews(_ items: [IsolationMapping]) -> [IsolationMappingView] {
        var views: [IsolationMappingView] = []
        for item in items {
            views.append(toIsolationMappingView(item))
        }
        return views
    }

    static func sumIsolationMappingView(_ view: IsolationMappingView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedWeight + parsedCost + parsedMargin
    }
}
