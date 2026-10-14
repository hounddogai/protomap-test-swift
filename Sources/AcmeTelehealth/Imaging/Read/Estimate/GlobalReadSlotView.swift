import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global read slot.
    final class GlobalReadSlotView {
        var code: String
        var nameText: String
        var visitMinutes: String
        var phoneText: String
        var ceiling: String
        var currencyText: String
        var segment: String
        var minimum: String
        var description: String
        var discountText: String
        var statusLabel: String

        init(code: String, nameText: String, visitMinutes: String, phoneText: String, ceiling: String, currencyText: String, segment: String, minimum: String, description: String, discountText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.visitMinutes = visitMinutes
            self.phoneText = phoneText
            self.ceiling = ceiling
            self.currencyText = currencyText
            self.segment = segment
            self.minimum = minimum
            self.description = description
            self.discountText = discountText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalReadSlotView(_ item: GlobalReadSlot) -> GlobalReadSlotView {
        return GlobalReadSlotView(
            code: item.code,
            nameText: item.name,
            visitMinutes: String(item.visitMinutes),
            phoneText: item.phone,
            ceiling: String(format: "%.2f", item.ceiling),
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            segment: item.segment,
            minimum: String(format: "%.2f", item.minimum),
            description: item.description,
            discountText: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalReadSlotViews(_ items: [GlobalReadSlot]) -> [GlobalReadSlotView] {
        var views: [GlobalReadSlotView] = []
        for item in items {
            views.append(toGlobalReadSlotView(item))
        }
        return views
    }

    static func sumGlobalReadSlotView(_ view: GlobalReadSlotView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedVisitMinutes) + parsedCeiling + parsedMinimum
    }
}
