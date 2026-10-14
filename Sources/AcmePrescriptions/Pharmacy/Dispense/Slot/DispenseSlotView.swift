import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense slot.
    final class DispenseSlotView {
        var code: String
        var name: String
        var startsAt: String
        var ceiling: String
        var refillsText: String
        var statusLabel: String

        init(code: String, name: String, startsAt: String, ceiling: String, refillsText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.ceiling = ceiling
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseSlotView(_ item: DispenseSlot) -> DispenseSlotView {
        return DispenseSlotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            startsAt: String(item.startsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseSlotViews(_ items: [DispenseSlot]) -> [DispenseSlotView] {
        var views: [DispenseSlotView] = []
        for item in items {
            views.append(toDispenseSlotView(item))
        }
        return views
    }

    static func sumDispenseSlotView(_ view: DispenseSlotView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedStartsAt) + parsedCeiling + Double(parsedRefills)
    }
}
