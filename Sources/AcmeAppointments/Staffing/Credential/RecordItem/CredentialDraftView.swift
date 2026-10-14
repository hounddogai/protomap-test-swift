import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential draft.
    final class CredentialDraftView {
        var code: String
        var title: String
        var contactEmail: String
        var payer: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, payer: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.payer = payer
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialDraftView(_ item: CredentialDraft) -> CredentialDraftView {
        return CredentialDraftView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            contactEmail: item.contactEmail,
            payer: item.payer,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialDraftViews(_ items: [CredentialDraft]) -> [CredentialDraftView] {
        var views: [CredentialDraftView] = []
        for item in items {
            views.append(toCredentialDraftView(item))
        }
        return views
    }

    static func sumCredentialDraftView(_ view: CredentialDraftView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
