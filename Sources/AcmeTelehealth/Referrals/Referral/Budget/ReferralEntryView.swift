import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral entry.
    final class ReferralEntryView {
        var codeText: String
        var nameText: String
        var localeText: String
        var weight: String
        var acuityText: String
        var notes: String
        var quantity: String
        var maximum: String
        var allergy: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, nameText: String, localeText: String, weight: String, acuityText: String, notes: String, quantity: String, maximum: String, allergy: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.localeText = localeText
            self.weight = weight
            self.acuityText = acuityText
            self.notes = notes
            self.quantity = quantity
            self.maximum = maximum
            self.allergy = allergy
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toReferralEntryView(_ item: ReferralEntry) -> ReferralEntryView {
        return ReferralEntryView(
            codeText: item.code,
            nameText: item.name,
            localeText: item.locale,
            weight: String(format: "%.2f", item.weight),
            acuityText: String(item.acuity),
            notes: item.notes,
            quantity: String(item.quantity),
            maximum: String(format: "%.2f", item.maximum),
            allergy: item.allergy,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralEntryViews(_ items: [ReferralEntry]) -> [ReferralEntryView] {
        var views: [ReferralEntryView] = []
        for item in items {
            views.append(toReferralEntryView(item))
        }
        return views
    }

    static func sumReferralEntryView(_ view: ReferralEntryView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedWeight + Double(parsedAcuity) + Double(parsedQuantity)
    }
}
