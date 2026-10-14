import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization notice.
    final class AuthorizationNoticeView {
        var code: String
        var label: String
        var cost: String
        var specialtyText: String
        var retries: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, cost: String, specialtyText: String, retries: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.specialtyText = specialtyText
            self.retries = retries
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationNoticeView(_ item: AuthorizationNotice) -> AuthorizationNoticeView {
        return AuthorizationNoticeView(
            code: item.code,
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            specialtyText: item.specialty,
            retries: String(item.retries),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationNoticeViews(_ items: [AuthorizationNotice]) -> [AuthorizationNoticeView] {
        var views: [AuthorizationNoticeView] = []
        for item in items {
            views.append(toAuthorizationNoticeView(item))
        }
        return views
    }

    static func sumAuthorizationNoticeView(_ view: AuthorizationNoticeView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedCost + Double(parsedRetries) + Double(parsedUpdatedAt)
    }
}
