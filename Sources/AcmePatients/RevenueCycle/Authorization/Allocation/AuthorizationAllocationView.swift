import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization allocation.
    final class AuthorizationAllocationView {
        var code: String
        var name: String
        var revisionText: String
        var updatedAt: String
        var notes: String
        var statusLabel: String

        init(code: String, name: String, revisionText: String, updatedAt: String, notes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.revisionText = revisionText
            self.updatedAt = updatedAt
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationAllocationView(_ item: AuthorizationAllocation) -> AuthorizationAllocationView {
        return AuthorizationAllocationView(
            code: item.code,
            name: item.name,
            revisionText: String(item.revision),
            updatedAt: String(item.updatedAt),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationAllocationViews(_ items: [AuthorizationAllocation]) -> [AuthorizationAllocationView] {
        var views: [AuthorizationAllocationView] = []
        for item in items {
            views.append(toAuthorizationAllocationView(item))
        }
        return views
    }

    static func sumAuthorizationAllocationView(_ view: AuthorizationAllocationView) throws -> Double {
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedRevision) + Double(parsedUpdatedAt)
    }
}
