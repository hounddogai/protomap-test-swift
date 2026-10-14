import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap audit.
    final class CareGapAuditView {
        var code: String
        var label: String
        var phone: String
        var expiresAtText: String
        var allergy: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, phone: String, expiresAtText: String, allergy: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.phone = phone
            self.expiresAtText = expiresAtText
            self.allergy = allergy
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapAuditView(_ item: CareGapAudit) -> CareGapAuditView {
        return CareGapAuditView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            expiresAtText: String(item.expiresAt),
            allergy: item.allergy,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapAuditViews(_ items: [CareGapAudit]) -> [CareGapAuditView] {
        var views: [CareGapAuditView] = []
        for item in items {
            views.append(toCareGapAuditView(item))
        }
        return views
    }

    static func sumCareGapAuditView(_ view: CareGapAuditView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedPriority)
    }
}
