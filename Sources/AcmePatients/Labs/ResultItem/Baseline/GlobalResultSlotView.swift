import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global result slot.
    final class GlobalResultSlotView {
        var codeText: String
        var name: String
        var payer: String
        var maximum: String
        var externalRef: String
        var notesText: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, payer: String, maximum: String, externalRef: String, notesText: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.payer = payer
            self.maximum = maximum
            self.externalRef = externalRef
            self.notesText = notesText
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalResultSlotView(_ item: GlobalResultSlot) -> GlobalResultSlotView {
        return GlobalResultSlotView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            payer: Kit.Text.truncate(item.payer, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            externalRef: Kit.Text.truncate(item.externalRef, limit: 40),
            notesText: Kit.Text.truncate(item.notes, limit: 40),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalResultSlotViews(_ items: [GlobalResultSlot]) -> [GlobalResultSlotView] {
        var views: [GlobalResultSlotView] = []
        for item in items {
            views.append(toGlobalResultSlotView(item))
        }
        return views
    }

    static func sumGlobalResultSlotView(_ view: GlobalResultSlotView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedMaximum + parsedCeiling
    }
}
