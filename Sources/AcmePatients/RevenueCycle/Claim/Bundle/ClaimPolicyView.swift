import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim policy.
    final class ClaimPolicyView {
        var code: String
        var nameText: String
        var timezoneText: String
        var revision: String
        var amount: String
        var pinnedText: String
        var copayText: String
        var limit: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, nameText: String, timezoneText: String, revision: String, amount: String, pinnedText: String, copayText: String, limit: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.timezoneText = timezoneText
            self.revision = revision
            self.amount = amount
            self.pinnedText = pinnedText
            self.copayText = copayText
            self.limit = limit
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toClaimPolicyView(_ item: ClaimPolicy) -> ClaimPolicyView {
        return ClaimPolicyView(
            code: item.code,
            nameText: item.name,
            timezoneText: Kit.Text.truncate(item.timezone, limit: 40),
            revision: String(item.revision),
            amount: String(format: "%.2f", item.amount),
            pinnedText: "\(item.pinned)",
            copayText: String(format: "%.2f", item.copay),
            limit: String(item.limit),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimPolicyViews(_ items: [ClaimPolicy]) -> [ClaimPolicyView] {
        var views: [ClaimPolicyView] = []
        for item in items {
            views.append(toClaimPolicyView(item))
        }
        return views
    }

    static func sumClaimPolicyView(_ view: ClaimPolicyView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRevision) + parsedAmount + parsedCopay
    }
}
