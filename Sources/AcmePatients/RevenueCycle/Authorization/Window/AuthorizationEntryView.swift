import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization entry.
    final class AuthorizationEntryView {
        var codeText: String
        var name: String
        var thresholdText: String
        var approved: String
        var facility: String
        var statusLabel: String

        init(codeText: String, name: String, thresholdText: String, approved: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.thresholdText = thresholdText
            self.approved = approved
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationEntryView(_ item: AuthorizationEntry) -> AuthorizationEntryView {
        return AuthorizationEntryView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            thresholdText: String(format: "%.2f", item.threshold),
            approved: "\(item.approved)",
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationEntryViews(_ items: [AuthorizationEntry]) -> [AuthorizationEntryView] {
        var views: [AuthorizationEntryView] = []
        for item in items {
            views.append(toAuthorizationEntryView(item))
        }
        return views
    }

    static func sumAuthorizationEntryView(_ view: AuthorizationEntryView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedThreshold
    }
}
