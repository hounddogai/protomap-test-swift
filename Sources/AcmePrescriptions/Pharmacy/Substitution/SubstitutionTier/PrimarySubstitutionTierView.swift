import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a primary substitution tier.
    final class PrimarySubstitutionTierView {
        var code: String
        var label: String
        var createdAt: String
        var segment: String
        var patientRef: String
        var approved: String
        var notesText: String
        var quantityText: String
        var phone: String
        var startsAt: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, segment: String, patientRef: String, approved: String, notesText: String, quantityText: String, phone: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.segment = segment
            self.patientRef = patientRef
            self.approved = approved
            self.notesText = notesText
            self.quantityText = quantityText
            self.phone = phone
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimarySubstitutionTierView(_ item: PrimarySubstitutionTier) -> PrimarySubstitutionTierView {
        return PrimarySubstitutionTierView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            createdAt: String(item.createdAt),
            segment: item.segment,
            patientRef: item.patientRef,
            approved: "\(item.approved)",
            notesText: item.notes,
            quantityText: String(item.quantity),
            phone: Kit.Text.truncate(item.phone, limit: 80),
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimarySubstitutionTierViews(_ items: [PrimarySubstitutionTier]) -> [PrimarySubstitutionTierView] {
        var views: [PrimarySubstitutionTierView] = []
        for item in items {
            views.append(toPrimarySubstitutionTierView(item))
        }
        return views
    }

    static func sumPrimarySubstitutionTierView(_ view: PrimarySubstitutionTierView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedQuantity) + Double(parsedStartsAt)
    }
}
