import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled eligibility draft.
    final class ScheduledEligibilityDraftView {
        var codeText: String
        var name: String
        var ceiling: String
        var ward: String
        var quantity: String
        var checksum: String
        var expiresAtText: String
        var externalRef: String
        var cost: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, name: String, ceiling: String, ward: String, quantity: String, checksum: String, expiresAtText: String, externalRef: String, cost: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ceiling = ceiling
            self.ward = ward
            self.quantity = quantity
            self.checksum = checksum
            self.expiresAtText = expiresAtText
            self.externalRef = externalRef
            self.cost = cost
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledEligibilityDraftView(_ item: ScheduledEligibilityDraft) -> ScheduledEligibilityDraftView {
        return ScheduledEligibilityDraftView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            ward: item.ward,
            quantity: String(item.quantity),
            checksum: item.checksum,
            expiresAtText: String(item.expiresAt),
            externalRef: item.externalRef,
            cost: String(format: "%.2f", item.cost),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledEligibilityDraftViews(_ items: [ScheduledEligibilityDraft]) -> [ScheduledEligibilityDraftView] {
        var views: [ScheduledEligibilityDraftView] = []
        for item in items {
            views.append(toScheduledEligibilityDraftView(item))
        }
        return views
    }

    static func sumScheduledEligibilityDraftView(_ view: ScheduledEligibilityDraftView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCeiling + Double(parsedQuantity) + Double(parsedExpiresAt)
    }
}
