import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization tier.
    final class AuthorizationTierView {
        var code: String
        var title: String
        var acuity: String
        var unitText: String
        var score: String
        var capacity: String
        var amount: String
        var label: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, title: String, acuity: String, unitText: String, score: String, capacity: String, amount: String, label: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.unitText = unitText
            self.score = score
            self.capacity = capacity
            self.amount = amount
            self.label = label
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationTierView(_ item: AuthorizationTier) -> AuthorizationTierView {
        return AuthorizationTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            acuity: String(item.acuity),
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            score: String(format: "%.2f", item.score),
            capacity: String(item.capacity),
            amount: String(format: "%.2f", item.amount),
            label: item.label,
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationTierViews(_ items: [AuthorizationTier]) -> [AuthorizationTierView] {
        var views: [AuthorizationTierView] = []
        for item in items {
            views.append(toAuthorizationTierView(item))
        }
        return views
    }

    static func sumAuthorizationTierView(_ view: AuthorizationTierView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedAcuity) + parsedScore + Double(parsedCapacity)
    }
}
