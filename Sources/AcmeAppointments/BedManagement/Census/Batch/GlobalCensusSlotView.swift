import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global census slot.
    final class GlobalCensusSlotView {
        var code: String
        var title: String
        var visitMinutes: String
        var locale: String
        var discountText: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, visitMinutes: String, locale: String, discountText: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.visitMinutes = visitMinutes
            self.locale = locale
            self.discountText = discountText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCensusSlotView(_ item: GlobalCensusSlot) -> GlobalCensusSlotView {
        return GlobalCensusSlotView(
            code: item.code,
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            locale: item.locale,
            discountText: String(format: "%.2f", item.discount),
            category: Kit.Text.truncate(item.category, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCensusSlotViews(_ items: [GlobalCensusSlot]) -> [GlobalCensusSlotView] {
        var views: [GlobalCensusSlotView] = []
        for item in items {
            views.append(toGlobalCensusSlotView(item))
        }
        return views
    }

    static func sumGlobalCensusSlotView(_ view: GlobalCensusSlotView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedVisitMinutes) + parsedDiscount
    }
}
