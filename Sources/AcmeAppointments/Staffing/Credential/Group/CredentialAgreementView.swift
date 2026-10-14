import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential agreement.
    final class CredentialAgreementView {
        var codeText: String
        var title: String
        var visitMinutesText: String
        var limit: String
        var createdAtText: String
        var categoryText: String
        var segment: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, title: String, visitMinutesText: String, limit: String, createdAtText: String, categoryText: String, segment: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.visitMinutesText = visitMinutesText
            self.limit = limit
            self.createdAtText = createdAtText
            self.categoryText = categoryText
            self.segment = segment
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialAgreementView(_ item: CredentialAgreement) -> CredentialAgreementView {
        return CredentialAgreementView(
            codeText: item.code,
            title: item.title,
            visitMinutesText: String(item.visitMinutes),
            limit: String(item.limit),
            createdAtText: String(item.createdAt),
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            segment: item.segment,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialAgreementViews(_ items: [CredentialAgreement]) -> [CredentialAgreementView] {
        var views: [CredentialAgreementView] = []
        for item in items {
            views.append(toCredentialAgreementView(item))
        }
        return views
    }

    static func sumCredentialAgreementView(_ view: CredentialAgreementView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedVisitMinutes) + Double(parsedLimit) + Double(parsedCreatedAt)
    }
}
