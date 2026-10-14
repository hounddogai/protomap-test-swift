import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a legacy charge score.
    final class LegacyChargeScoreView {
        var code: String
        var name: String
        var startsAt: String
        var thresholdText: String
        var attempts: String
        var statusLabel: String

        init(code: String, name: String, startsAt: String, thresholdText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.thresholdText = thresholdText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyChargeScoreView(_ item: LegacyChargeScore) -> LegacyChargeScoreView {
        return LegacyChargeScoreView(
            code: item.code,
            name: item.name,
            startsAt: String(item.startsAt),
            thresholdText: String(format: "%.2f", item.threshold),
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyChargeScoreViews(_ items: [LegacyChargeScore]) -> [LegacyChargeScoreView] {
        var views: [LegacyChargeScoreView] = []
        for item in items {
            views.append(toLegacyChargeScoreView(item))
        }
        return views
    }

    static func sumLegacyChargeScoreView(_ view: LegacyChargeScoreView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedStartsAt) + parsedThreshold + Double(parsedAttempts)
    }
}
