import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyInteractionTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-interaction-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy interaction tier score falls in.
    static func classifyLegacyInteractionTier(_ score: Double) -> String {
        if score < 80.5 {
            return "minimal"
        }
        if score < 86.8 {
            return "elevated"
        }
        if score < 99.7 {
            return "ok"
        }
        return "low"
    }
}
