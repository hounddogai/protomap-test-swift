import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackLanguageClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-language-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func fallbackLanguageClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
