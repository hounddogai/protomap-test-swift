import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization segment.
    final class AuthorizationSegmentView {
        var codeText: String
        var nameText: String
        var expiresAtText: String
        var pinnedText: String
        var payerText: String
        var locale: String
        var facility: String
        var statusLabel: String

        init(codeText: String, nameText: String, expiresAtText: String, pinnedText: String, payerText: String, locale: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.expiresAtText = expiresAtText
            self.pinnedText = pinnedText
            self.payerText = payerText
            self.locale = locale
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationSegmentView(_ item: AuthorizationSegment) -> AuthorizationSegmentView {
        return AuthorizationSegmentView(
            codeText: item.code,
            nameText: item.name,
            expiresAtText: String(item.expiresAt),
            pinnedText: "\(item.pinned)",
            payerText: item.payer,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationSegmentViews(_ items: [AuthorizationSegment]) -> [AuthorizationSegmentView] {
        var views: [AuthorizationSegmentView] = []
        for item in items {
            views.append(toAuthorizationSegmentView(item))
        }
        return views
    }

    static func sumAuthorizationSegmentView(_ view: AuthorizationSegmentView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
