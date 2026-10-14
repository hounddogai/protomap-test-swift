import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback rounding slot.
    final class FallbackRoundingSlotView {
        var code: String
        var name: String
        var active: String
        var margin: String
        var discount: String
        var patientRefText: String
        var limit: String
        var checksum: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, active: String, margin: String, discount: String, patientRefText: String, limit: String, checksum: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.active = active
            self.margin = margin
            self.discount = discount
            self.patientRefText = patientRefText
            self.limit = limit
            self.checksum = checksum
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackRoundingSlotView(_ item: FallbackRoundingSlot) -> FallbackRoundingSlotView {
        return FallbackRoundingSlotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            active: "\(item.active)",
            margin: String(format: "%.2f", item.margin),
            discount: String(format: "%.2f", item.discount),
            patientRefText: item.patientRef,
            limit: String(item.limit),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackRoundingSlotViews(_ items: [FallbackRoundingSlot]) -> [FallbackRoundingSlotView] {
        var views: [FallbackRoundingSlotView] = []
        for item in items {
            views.append(toFallbackRoundingSlotView(item))
        }
        return views
    }

    static func sumFallbackRoundingSlotView(_ view: FallbackRoundingSlotView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedMargin + parsedDiscount + Double(parsedLimit)
    }
}
