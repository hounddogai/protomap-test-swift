import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority slot.
    final class PrioritySlotView {
        var code: String
        var title: String
        var bed: String
        var amount: String
        var regionText: String
        var statusLabel: String

        init(code: String, title: String, bed: String, amount: String, regionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.bed = bed
            self.amount = amount
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toPrioritySlotView(_ item: PrioritySlot) -> PrioritySlotView {
        return PrioritySlotView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            amount: String(format: "%.2f", item.amount),
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrioritySlotViews(_ items: [PrioritySlot]) -> [PrioritySlotView] {
        var views: [PrioritySlotView] = []
        for item in items {
            views.append(toPrioritySlotView(item))
        }
        return views
    }

    static func sumPrioritySlotView(_ view: PrioritySlotView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
