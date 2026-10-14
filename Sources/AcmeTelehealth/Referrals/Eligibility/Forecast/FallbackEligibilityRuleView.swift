import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback eligibility rule.
    final class FallbackEligibilityRuleView {
        var code: String
        var title: String
        var clinicianID: String
        var score: String
        var ownerIDText: String
        var graceDays: String
        var versionText: String
        var statusLabel: String

        init(code: String, title: String, clinicianID: String, score: String, ownerIDText: String, graceDays: String, versionText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.score = score
            self.ownerIDText = ownerIDText
            self.graceDays = graceDays
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackEligibilityRuleView(_ item: FallbackEligibilityRule) -> FallbackEligibilityRuleView {
        return FallbackEligibilityRuleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            clinicianID: item.clinicianID,
            score: String(format: "%.2f", item.score),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 120),
            graceDays: String(item.graceDays),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackEligibilityRuleViews(_ items: [FallbackEligibilityRule]) -> [FallbackEligibilityRuleView] {
        var views: [FallbackEligibilityRuleView] = []
        for item in items {
            views.append(toFallbackEligibilityRuleView(item))
        }
        return views
    }

    static func sumFallbackEligibilityRuleView(_ view: FallbackEligibilityRuleView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedScore + Double(parsedGraceDays) + Double(parsedVersion)
    }
}
