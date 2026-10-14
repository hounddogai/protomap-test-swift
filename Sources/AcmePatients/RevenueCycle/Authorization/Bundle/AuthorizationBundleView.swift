import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization bundle.
    final class AuthorizationBundleView {
        var code: String
        var title: String
        var approvedText: String
        var specialty: String
        var createdAt: String
        var statusLabel: String

        init(code: String, title: String, approvedText: String, specialty: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approvedText = approvedText
            self.specialty = specialty
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationBundleView(_ item: AuthorizationBundle) -> AuthorizationBundleView {
        return AuthorizationBundleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            approvedText: "\(item.approved)",
            specialty: item.specialty,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationBundleViews(_ items: [AuthorizationBundle]) -> [AuthorizationBundleView] {
        var views: [AuthorizationBundleView] = []
        for item in items {
            views.append(toAuthorizationBundleView(item))
        }
        return views
    }

    static func sumAuthorizationBundleView(_ view: AuthorizationBundleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
