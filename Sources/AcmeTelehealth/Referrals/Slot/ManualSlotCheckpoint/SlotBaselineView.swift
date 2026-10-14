import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot baseline.
    final class SlotBaselineView {
        var codeText: String
        var label: String
        var cost: String
        var capacity: String
        var maximumText: String
        var wardText: String
        var locale: String
        var payer: String
        var approved: String
        var statusLabel: String

        init(codeText: String, label: String, cost: String, capacity: String, maximumText: String, wardText: String, locale: String, payer: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.cost = cost
            self.capacity = capacity
            self.maximumText = maximumText
            self.wardText = wardText
            self.locale = locale
            self.payer = payer
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toSlotBaselineView(_ item: SlotBaseline) -> SlotBaselineView {
        return SlotBaselineView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            cost: String(format: "%.2f", item.cost),
            capacity: String(item.capacity),
            maximumText: String(format: "%.2f", item.maximum),
            wardText: item.ward,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            payer: item.payer,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotBaselineViews(_ items: [SlotBaseline]) -> [SlotBaselineView] {
        var views: [SlotBaselineView] = []
        for item in items {
            views.append(toSlotBaselineView(item))
        }
        return views
    }

    static func sumSlotBaselineView(_ view: SlotBaselineView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCost + Double(parsedCapacity) + parsedMaximum
    }
}
