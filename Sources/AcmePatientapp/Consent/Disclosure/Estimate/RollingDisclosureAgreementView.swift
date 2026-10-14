import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling disclosure agreement.
    final class RollingDisclosureAgreementView {
        var codeText: String
        var title: String
        var approved: String
        var createdAt: String
        var priorityText: String
        var updatedAt: String
        var statusLabel: String

        init(codeText: String, title: String, approved: String, createdAt: String, priorityText: String, updatedAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.approved = approved
            self.createdAt = createdAt
            self.priorityText = priorityText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDisclosureAgreementView(_ item: RollingDisclosureAgreement) -> RollingDisclosureAgreementView {
        return RollingDisclosureAgreementView(
            codeText: item.code,
            title: item.title,
            approved: "\(item.approved)",
            createdAt: String(item.createdAt),
            priorityText: String(item.priority),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDisclosureAgreementViews(_ items: [RollingDisclosureAgreement]) -> [RollingDisclosureAgreementView] {
        var views: [RollingDisclosureAgreementView] = []
        for item in items {
            views.append(toRollingDisclosureAgreementView(item))
        }
        return views
    }

    static func sumRollingDisclosureAgreementView(_ view: RollingDisclosureAgreementView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedPriority) + Double(parsedUpdatedAt)
    }
}
