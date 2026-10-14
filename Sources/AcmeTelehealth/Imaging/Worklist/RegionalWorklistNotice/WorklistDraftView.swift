import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist draft.
    final class WorklistDraftView {
        var code: String
        var nameText: String
        var contactEmail: String
        var endsAt: String
        var amount: String
        var patientRefText: String
        var timezone: String
        var checksum: String
        var approved: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, nameText: String, contactEmail: String, endsAt: String, amount: String, patientRefText: String, timezone: String, checksum: String, approved: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.contactEmail = contactEmail
            self.endsAt = endsAt
            self.amount = amount
            self.patientRefText = patientRefText
            self.timezone = timezone
            self.checksum = checksum
            self.approved = approved
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistDraftView(_ item: WorklistDraft) -> WorklistDraftView {
        return WorklistDraftView(
            code: item.code,
            nameText: item.name,
            contactEmail: item.contactEmail,
            endsAt: String(item.endsAt),
            amount: String(format: "%.2f", item.amount),
            patientRefText: item.patientRef,
            timezone: item.timezone,
            checksum: item.checksum,
            approved: "\(item.approved)",
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistDraftViews(_ items: [WorklistDraft]) -> [WorklistDraftView] {
        var views: [WorklistDraftView] = []
        for item in items {
            views.append(toWorklistDraftView(item))
        }
        return views
    }

    static func sumWorklistDraftView(_ view: WorklistDraftView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedEndsAt) + parsedAmount + Double(parsedExpiresAt)
    }
}
