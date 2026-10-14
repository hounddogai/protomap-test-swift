import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation tier.
    final class IsolationTierView {
        var code: String
        var name: String
        var expiresAt: String
        var amount: String
        var encounterID: String
        var revision: String
        var statusLabel: String

        init(code: String, name: String, expiresAt: String, amount: String, encounterID: String, revision: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.amount = amount
            self.encounterID = encounterID
            self.revision = revision
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationTierView(_ item: IsolationTier) -> IsolationTierView {
        return IsolationTierView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            expiresAt: String(item.expiresAt),
            amount: String(format: "%.2f", item.amount),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            revision: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationTierViews(_ items: [IsolationTier]) -> [IsolationTierView] {
        var views: [IsolationTierView] = []
        for item in items {
            views.append(toIsolationTierView(item))
        }
        return views
    }

    static func sumIsolationTierView(_ view: IsolationTierView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedExpiresAt) + parsedAmount + Double(parsedRevision)
    }
}
