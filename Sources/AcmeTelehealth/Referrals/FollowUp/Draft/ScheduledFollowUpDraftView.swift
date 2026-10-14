import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a scheduled follow up draft.
    final class ScheduledFollowUpDraftView {
        var code: String
        var label: String
        var limit: String
        var expiresAt: String
        var approved: String
        var discount: String
        var externalRef: String
        var statusLabel: String

        init(code: String, label: String, limit: String, expiresAt: String, approved: String, discount: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limit = limit
            self.expiresAt = expiresAt
            self.approved = approved
            self.discount = discount
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFollowUpDraftView(_ item: ScheduledFollowUpDraft) -> ScheduledFollowUpDraftView {
        return ScheduledFollowUpDraftView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: Kit.Text.truncate(item.label, limit: 120),
            limit: String(item.limit),
            expiresAt: String(item.expiresAt),
            approved: "\(item.approved)",
            discount: String(format: "%.2f", item.discount),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFollowUpDraftViews(_ items: [ScheduledFollowUpDraft]) -> [ScheduledFollowUpDraftView] {
        var views: [ScheduledFollowUpDraftView] = []
        for item in items {
            views.append(toScheduledFollowUpDraftView(item))
        }
        return views
    }

    static func sumScheduledFollowUpDraftView(_ view: ScheduledFollowUpDraftView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedLimit) + Double(parsedExpiresAt) + parsedDiscount
    }
}
