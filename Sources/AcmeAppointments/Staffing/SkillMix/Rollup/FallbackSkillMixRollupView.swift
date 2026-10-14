import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a fallback skill mix rollup.
    final class FallbackSkillMixRollupView {
        var code: String
        var name: String
        var externalRef: String
        var endsAt: String
        var copay: String
        var scoreText: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, externalRef: String, endsAt: String, copay: String, scoreText: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.externalRef = externalRef
            self.endsAt = endsAt
            self.copay = copay
            self.scoreText = scoreText
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackSkillMixRollupView(_ item: FallbackSkillMixRollup) -> FallbackSkillMixRollupView {
        return FallbackSkillMixRollupView(
            code: item.code,
            name: item.name,
            externalRef: item.externalRef,
            endsAt: String(item.endsAt),
            copay: String(format: "%.2f", item.copay),
            scoreText: String(format: "%.2f", item.score),
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackSkillMixRollupViews(_ items: [FallbackSkillMixRollup]) -> [FallbackSkillMixRollupView] {
        var views: [FallbackSkillMixRollupView] = []
        for item in items {
            views.append(toFallbackSkillMixRollupView(item))
        }
        return views
    }

    static func sumFallbackSkillMixRollupView(_ view: FallbackSkillMixRollupView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedEndsAt) + parsedCopay + parsedScore
    }
}
