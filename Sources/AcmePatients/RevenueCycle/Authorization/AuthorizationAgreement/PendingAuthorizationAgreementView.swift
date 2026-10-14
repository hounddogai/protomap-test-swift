import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending authorization agreement.
    final class PendingAuthorizationAgreementView {
        var code: String
        var title: String
        var version: String
        var refillsText: String
        var approved: String
        var unit: String
        var updatedAt: String
        var ward: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, title: String, version: String, refillsText: String, approved: String, unit: String, updatedAt: String, ward: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.version = version
            self.refillsText = refillsText
            self.approved = approved
            self.unit = unit
            self.updatedAt = updatedAt
            self.ward = ward
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingAuthorizationAgreementView(_ item: PendingAuthorizationAgreement) -> PendingAuthorizationAgreementView {
        return PendingAuthorizationAgreementView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 40),
            version: String(item.version),
            refillsText: String(item.refills),
            approved: "\(item.approved)",
            unit: item.unit,
            updatedAt: String(item.updatedAt),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingAuthorizationAgreementViews(_ items: [PendingAuthorizationAgreement]) -> [PendingAuthorizationAgreementView] {
        var views: [PendingAuthorizationAgreementView] = []
        for item in items {
            views.append(toPendingAuthorizationAgreementView(item))
        }
        return views
    }

    static func sumPendingAuthorizationAgreementView(_ view: PendingAuthorizationAgreementView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedVersion) + Double(parsedRefills) + Double(parsedUpdatedAt)
    }
}
