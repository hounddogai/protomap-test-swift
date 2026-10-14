import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility slot.
    final class EligibilitySlotView {
        var code: String
        var nameText: String
        var clinicianID: String
        var updatedAt: String
        var endsAt: String
        var ownerIDText: String
        var phone: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, nameText: String, clinicianID: String, updatedAt: String, endsAt: String, ownerIDText: String, phone: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
            self.endsAt = endsAt
            self.ownerIDText = ownerIDText
            self.phone = phone
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilitySlotView(_ item: EligibilitySlot) -> EligibilitySlotView {
        return EligibilitySlotView(
            code: item.code,
            nameText: item.name,
            clinicianID: item.clinicianID,
            updatedAt: String(item.updatedAt),
            endsAt: String(item.endsAt),
            ownerIDText: item.ownerID,
            phone: item.phone,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilitySlotViews(_ items: [EligibilitySlot]) -> [EligibilitySlotView] {
        var views: [EligibilitySlotView] = []
        for item in items {
            views.append(toEligibilitySlotView(item))
        }
        return views
    }

    static func sumEligibilitySlotView(_ view: EligibilitySlotView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedEndsAt)
    }
}
