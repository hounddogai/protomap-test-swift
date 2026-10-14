import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance audit.
    final class RemittanceAuditView {
        var codeText: String
        var label: String
        var ownerID: String
        var revision: String
        var specialtyText: String
        var country: String
        var expiresAtText: String
        var title: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, label: String, ownerID: String, revision: String, specialtyText: String, country: String, expiresAtText: String, title: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ownerID = ownerID
            self.revision = revision
            self.specialtyText = specialtyText
            self.country = country
            self.expiresAtText = expiresAtText
            self.title = title
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceAuditView(_ item: RemittanceAudit) -> RemittanceAuditView {
        return RemittanceAuditView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            ownerID: item.ownerID,
            revision: String(item.revision),
            specialtyText: item.specialty,
            country: item.country,
            expiresAtText: String(item.expiresAt),
            title: Kit.Text.truncate(item.title, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceAuditViews(_ items: [RemittanceAudit]) -> [RemittanceAuditView] {
        var views: [RemittanceAuditView] = []
        for item in items {
            views.append(toRemittanceAuditView(item))
        }
        return views
    }

    static func sumRemittanceAuditView(_ view: RemittanceAuditView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRevision) + Double(parsedExpiresAt) + parsedCeiling
    }
}
