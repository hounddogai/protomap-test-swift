import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential adjustment.
    final class CredentialAdjustmentView {
        var codeText: String
        var nameText: String
        var maximum: String
        var pinnedText: String
        var summary: String
        var weight: String
        var currencyText: String
        var discountText: String
        var facilityText: String
        var floorValueText: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, nameText: String, maximum: String, pinnedText: String, summary: String, weight: String, currencyText: String, discountText: String, facilityText: String, floorValueText: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.maximum = maximum
            self.pinnedText = pinnedText
            self.summary = summary
            self.weight = weight
            self.currencyText = currencyText
            self.discountText = discountText
            self.facilityText = facilityText
            self.floorValueText = floorValueText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialAdjustmentView(_ item: CredentialAdjustment) -> CredentialAdjustmentView {
        return CredentialAdjustmentView(
            codeText: item.code,
            nameText: item.name,
            maximum: String(format: "%.2f", item.maximum),
            pinnedText: "\(item.pinned)",
            summary: Kit.Text.truncate(item.summary, limit: 64),
            weight: String(format: "%.2f", item.weight),
            currencyText: item.currency,
            discountText: String(format: "%.2f", item.discount),
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            floorValueText: String(format: "%.2f", item.floorValue),
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialAdjustmentViews(_ items: [CredentialAdjustment]) -> [CredentialAdjustmentView] {
        var views: [CredentialAdjustmentView] = []
        for item in items {
            views.append(toCredentialAdjustmentView(item))
        }
        return views
    }

    static func sumCredentialAdjustmentView(_ view: CredentialAdjustmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedMaximum + parsedWeight + parsedDiscount
    }
}
