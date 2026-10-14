import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a lenient outreach audit.
    final class LenientOutreachAuditView {
        var code: String
        var title: String
        var ward: String
        var encounterIDText: String
        var externalRefText: String
        var bed: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, title: String, ward: String, encounterIDText: String, externalRefText: String, bed: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ward = ward
            self.encounterIDText = encounterIDText
            self.externalRefText = externalRefText
            self.bed = bed
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientOutreachAuditView(_ item: LenientOutreachAudit) -> LenientOutreachAuditView {
        return LenientOutreachAuditView(
            code: item.code,
            title: item.title,
            ward: item.ward,
            encounterIDText: item.encounterID,
            externalRefText: item.externalRef,
            bed: item.bed,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientOutreachAuditViews(_ items: [LenientOutreachAudit]) -> [LenientOutreachAuditView] {
        var views: [LenientOutreachAuditView] = []
        for item in items {
            views.append(toLenientOutreachAuditView(item))
        }
        return views
    }

    static func sumLenientOutreachAuditView(_ view: LenientOutreachAuditView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
