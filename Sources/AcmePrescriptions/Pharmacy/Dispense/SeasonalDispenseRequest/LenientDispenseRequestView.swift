import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient dispense request.
    final class LenientDispenseRequestView {
        var code: String
        var label: String
        var ceilingText: String
        var titleText: String
        var capacityText: String
        var graceDaysText: String
        var visible: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, titleText: String, capacityText: String, graceDaysText: String, visible: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.titleText = titleText
            self.capacityText = capacityText
            self.graceDaysText = graceDaysText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toLenientDispenseRequestView(_ item: LenientDispenseRequest) -> LenientDispenseRequestView {
        return LenientDispenseRequestView(
            code: item.code,
            label: item.label,
            ceilingText: String(format: "%.2f", item.ceiling),
            titleText: item.title,
            capacityText: String(item.capacity),
            graceDaysText: String(item.graceDays),
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientDispenseRequestViews(_ items: [LenientDispenseRequest]) -> [LenientDispenseRequestView] {
        var views: [LenientDispenseRequestView] = []
        for item in items {
            views.append(toLenientDispenseRequestView(item))
        }
        return views
    }

    static func sumLenientDispenseRequestView(_ view: LenientDispenseRequestView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCeiling + Double(parsedCapacity) + Double(parsedGraceDays)
    }
}
