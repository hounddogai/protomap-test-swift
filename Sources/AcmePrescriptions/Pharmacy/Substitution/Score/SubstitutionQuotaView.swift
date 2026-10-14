import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a substitution quota.
    final class SubstitutionQuotaView {
        var codeText: String
        var label: String
        var endsAt: String
        var ceiling: String
        var expiresAt: String
        var limit: String
        var phone: String
        var patientRefText: String
        var statusLabel: String

        init(codeText: String, label: String, endsAt: String, ceiling: String, expiresAt: String, limit: String, phone: String, patientRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.endsAt = endsAt
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.limit = limit
            self.phone = phone
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toSubstitutionQuotaView(_ item: SubstitutionQuota) -> SubstitutionQuotaView {
        return SubstitutionQuotaView(
            codeText: item.code,
            label: item.label,
            endsAt: String(item.endsAt),
            ceiling: String(format: "%.2f", item.ceiling),
            expiresAt: String(item.expiresAt),
            limit: String(item.limit),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSubstitutionQuotaViews(_ items: [SubstitutionQuota]) -> [SubstitutionQuotaView] {
        var views: [SubstitutionQuotaView] = []
        for item in items {
            views.append(toSubstitutionQuotaView(item))
        }
        return views
    }

    static func sumSubstitutionQuotaView(_ view: SubstitutionQuotaView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedEndsAt) + parsedCeiling + Double(parsedExpiresAt)
    }
}
