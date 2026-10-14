import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient outreach slot.
    final class LenientOutreachSlotView {
        var codeText: String
        var title: String
        var clinicianID: String
        var capacity: String
        var amountText: String
        var statusLabel: String

        init(codeText: String, title: String, clinicianID: String, capacity: String, amountText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.clinicianID = clinicianID
            self.capacity = capacity
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOutreachSlotView(_ item: LenientOutreachSlot) -> LenientOutreachSlotView {
        return LenientOutreachSlotView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 120),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 80),
            capacity: String(item.capacity),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOutreachSlotViews(_ items: [LenientOutreachSlot]) -> [LenientOutreachSlotView] {
        var views: [LenientOutreachSlotView] = []
        for item in items {
            views.append(toLenientOutreachSlotView(item))
        }
        return views
    }

    static func sumLenientOutreachSlotView(_ view: LenientOutreachSlotView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedCapacity) + parsedAmount
    }
}
