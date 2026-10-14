import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot template.
    final class SlotTemplateView {
        var code: String
        var labelText: String
        var maximum: String
        var rate: String
        var bed: String
        var unit: String
        var statusLabel: String

        init(code: String, labelText: String, maximum: String, rate: String, bed: String, unit: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.maximum = maximum
            self.rate = rate
            self.bed = bed
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toSlotTemplateView(_ item: SlotTemplate) -> SlotTemplateView {
        return SlotTemplateView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            rate: String(format: "%.2f", item.rate),
            bed: item.bed,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotTemplateViews(_ items: [SlotTemplate]) -> [SlotTemplateView] {
        var views: [SlotTemplateView] = []
        for item in items {
            views.append(toSlotTemplateView(item))
        }
        return views
    }

    static func sumSlotTemplateView(_ view: SlotTemplateView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + parsedRate
    }
}
