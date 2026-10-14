import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback goal claim.
    final class FallbackGoalClaimView {
        var code: String
        var title: String
        var region: String
        var attempts: String
        var ownerID: String
        var acuity: String
        var bedText: String
        var statusLabel: String

        init(code: String, title: String, region: String, attempts: String, ownerID: String, acuity: String, bedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.attempts = attempts
            self.ownerID = ownerID
            self.acuity = acuity
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackGoalClaimView(_ item: FallbackGoalClaim) -> FallbackGoalClaimView {
        return FallbackGoalClaimView(
            code: item.code,
            title: item.title,
            region: Kit.Text.truncate(item.region, limit: 120),
            attempts: String(item.attempts),
            ownerID: item.ownerID,
            acuity: String(item.acuity),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackGoalClaimViews(_ items: [FallbackGoalClaim]) -> [FallbackGoalClaimView] {
        var views: [FallbackGoalClaimView] = []
        for item in items {
            views.append(toFallbackGoalClaimView(item))
        }
        return views
    }

    static func sumFallbackGoalClaimView(_ view: FallbackGoalClaimView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAttempts) + Double(parsedAcuity)
    }
}
