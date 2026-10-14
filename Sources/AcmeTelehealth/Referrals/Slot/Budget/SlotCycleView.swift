import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot cycle.
    final class SlotCycleView {
        var code: String
        var name: String
        var ceiling: String
        var archived: String
        var graceDays: String
        var labelText: String
        var statusLabel: String

        init(code: String, name: String, ceiling: String, archived: String, graceDays: String, labelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.archived = archived
            self.graceDays = graceDays
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotCycleView(_ item: SlotCycle) -> SlotCycleView {
        return SlotCycleView(
            code: item.code,
            name: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            archived: "\(item.archived)",
            graceDays: String(item.graceDays),
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotCycleViews(_ items: [SlotCycle]) -> [SlotCycleView] {
        var views: [SlotCycleView] = []
        for item in items {
            views.append(toSlotCycleView(item))
        }
        return views
    }

    static func sumSlotCycleView(_ view: SlotCycleView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedCeiling + Double(parsedGraceDays)
    }
}
