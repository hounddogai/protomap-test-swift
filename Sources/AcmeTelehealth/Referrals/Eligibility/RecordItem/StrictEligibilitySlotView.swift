import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict eligibility slot.
    final class StrictEligibilitySlotView {
        var code: String
        var name: String
        var quantityText: String
        var encounterID: String
        var ownerIDText: String
        var patientRef: String
        var clinicianID: String
        var createdAt: String
        var attempts: String
        var retriesText: String
        var statusLabel: String

        init(code: String, name: String, quantityText: String, encounterID: String, ownerIDText: String, patientRef: String, clinicianID: String, createdAt: String, attempts: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantityText = quantityText
            self.encounterID = encounterID
            self.ownerIDText = ownerIDText
            self.patientRef = patientRef
            self.clinicianID = clinicianID
            self.createdAt = createdAt
            self.attempts = attempts
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictEligibilitySlotView(_ item: StrictEligibilitySlot) -> StrictEligibilitySlotView {
        return StrictEligibilitySlotView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            quantityText: String(item.quantity),
            encounterID: item.encounterID,
            ownerIDText: item.ownerID,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 64),
            createdAt: String(item.createdAt),
            attempts: String(item.attempts),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictEligibilitySlotViews(_ items: [StrictEligibilitySlot]) -> [StrictEligibilitySlotView] {
        var views: [StrictEligibilitySlotView] = []
        for item in items {
            views.append(toStrictEligibilitySlotView(item))
        }
        return views
    }

    static func sumStrictEligibilitySlotView(_ view: StrictEligibilitySlotView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedQuantity) + Double(parsedCreatedAt) + Double(parsedAttempts)
    }
}
