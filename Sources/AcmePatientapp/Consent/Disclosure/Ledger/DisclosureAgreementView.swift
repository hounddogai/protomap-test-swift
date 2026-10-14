import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure agreement.
    final class DisclosureAgreementView {
        var code: String
        var title: String
        var locale: String
        var createdAt: String
        var revisionText: String
        var statusLabel: String

        init(code: String, title: String, locale: String, createdAt: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.locale = locale
            self.createdAt = createdAt
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureAgreementView(_ item: DisclosureAgreement) -> DisclosureAgreementView {
        return DisclosureAgreementView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 64),
            locale: item.locale,
            createdAt: String(item.createdAt),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureAgreementViews(_ items: [DisclosureAgreement]) -> [DisclosureAgreementView] {
        var views: [DisclosureAgreementView] = []
        for item in items {
            views.append(toDisclosureAgreementView(item))
        }
        return views
    }

    static func sumDisclosureAgreementView(_ view: DisclosureAgreementView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRevision)
    }
}
