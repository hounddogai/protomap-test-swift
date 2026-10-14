import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy alert slot.
    final class LegacyAlertSlotView {
        var codeText: String
        var label: String
        var channel: String
        var minimum: String
        var discount: String
        var ownerIDText: String
        var pinned: String
        var graceDaysText: String
        var statusLabel: String

        init(codeText: String, label: String, channel: String, minimum: String, discount: String, ownerIDText: String, pinned: String, graceDaysText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.channel = channel
            self.minimum = minimum
            self.discount = discount
            self.ownerIDText = ownerIDText
            self.pinned = pinned
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAlertSlotView(_ item: LegacyAlertSlot) -> LegacyAlertSlotView {
        return LegacyAlertSlotView(
            codeText: item.code,
            label: item.label,
            channel: Kit.Text.truncate(item.channel, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            discount: String(format: "%.2f", item.discount),
            ownerIDText: item.ownerID,
            pinned: "\(item.pinned)",
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAlertSlotViews(_ items: [LegacyAlertSlot]) -> [LegacyAlertSlotView] {
        var views: [LegacyAlertSlotView] = []
        for item in items {
            views.append(toLegacyAlertSlotView(item))
        }
        return views
    }

    static func sumLegacyAlertSlotView(_ view: LegacyAlertSlotView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMinimum + parsedDiscount + Double(parsedGraceDays)
    }
}
