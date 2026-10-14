import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient authorization milestone.
    final class LenientAuthorizationMilestoneView {
        var code: String
        var label: String
        var currency: String
        var minimum: String
        var endsAt: String
        var expiresAt: String
        var score: String
        var statusLabel: String

        init(code: String, label: String, currency: String, minimum: String, endsAt: String, expiresAt: String, score: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.currency = currency
            self.minimum = minimum
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toLenientAuthorizationMilestoneView(_ item: LenientAuthorizationMilestone) -> LenientAuthorizationMilestoneView {
        return LenientAuthorizationMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            currency: item.currency,
            minimum: String(format: "%.2f", item.minimum),
            endsAt: String(item.endsAt),
            expiresAt: String(item.expiresAt),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientAuthorizationMilestoneViews(_ items: [LenientAuthorizationMilestone]) -> [LenientAuthorizationMilestoneView] {
        var views: [LenientAuthorizationMilestoneView] = []
        for item in items {
            views.append(toLenientAuthorizationMilestoneView(item))
        }
        return views
    }

    static func sumLenientAuthorizationMilestoneView(_ view: LenientAuthorizationMilestoneView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedMinimum + Double(parsedEndsAt) + Double(parsedExpiresAt)
    }
}
