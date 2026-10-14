import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a lenient claim policy.
    final class LenientClaimPolicyView {
        var code: String
        var name: String
        var description: String
        var region: String
        var archived: String
        var locale: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, description: String, region: String, archived: String, locale: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.description = description
            self.region = region
            self.archived = archived
            self.locale = locale
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toLenientClaimPolicyView(_ item: LenientClaimPolicy) -> LenientClaimPolicyView {
        return LenientClaimPolicyView(
            code: item.code,
            name: item.name,
            description: item.description,
            region: item.region,
            archived: "\(item.archived)",
            locale: Kit.Text.truncate(item.locale, limit: 80),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientClaimPolicyViews(_ items: [LenientClaimPolicy]) -> [LenientClaimPolicyView] {
        var views: [LenientClaimPolicyView] = []
        for item in items {
            views.append(toLenientClaimPolicyView(item))
        }
        return views
    }

    static func sumLenientClaimPolicyView(_ view: LenientClaimPolicyView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
