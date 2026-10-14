import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization variance.
    final class AuthorizationVarianceView {
        var codeText: String
        var title: String
        var externalRef: String
        var margin: String
        var active: String
        var expiresAt: String
        var statusLabel: String

        init(codeText: String, title: String, externalRef: String, margin: String, active: String, expiresAt: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.externalRef = externalRef
            self.margin = margin
            self.active = active
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationVarianceView(_ item: AuthorizationVariance) -> AuthorizationVarianceView {
        return AuthorizationVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            externalRef: item.externalRef,
            margin: String(format: "%.2f", item.margin),
            active: "\(item.active)",
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationVarianceViews(_ items: [AuthorizationVariance]) -> [AuthorizationVarianceView] {
        var views: [AuthorizationVarianceView] = []
        for item in items {
            views.append(toAuthorizationVarianceView(item))
        }
        return views
    }

    static func sumAuthorizationVarianceView(_ view: AuthorizationVarianceView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMargin + Double(parsedExpiresAt)
    }
}
