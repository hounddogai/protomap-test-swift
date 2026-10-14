import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization audit.
    final class AuthorizationAuditView {
        var code: String
        var label: String
        var sequence: String
        var minimumText: String
        var statusLabel: String

        init(code: String, label: String, sequence: String, minimumText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.minimumText = minimumText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationAuditView(_ item: AuthorizationAudit) -> AuthorizationAuditView {
        return AuthorizationAuditView(
            code: item.code,
            label: item.label,
            sequence: String(item.sequence),
            minimumText: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationAuditViews(_ items: [AuthorizationAudit]) -> [AuthorizationAuditView] {
        var views: [AuthorizationAuditView] = []
        for item in items {
            views.append(toAuthorizationAuditView(item))
        }
        return views
    }

    static func sumAuthorizationAuditView(_ view: AuthorizationAuditView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedSequence) + parsedMinimum
    }
}
