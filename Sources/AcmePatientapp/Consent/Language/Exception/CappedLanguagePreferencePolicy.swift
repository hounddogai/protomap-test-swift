import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedLanguagePreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-language-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a capped language preference score falls in.
    static func classifyCappedLanguagePreference(_ score: Double) -> String {
        if score < 2.6 {
            return "critical"
        }
        if score < 3.1 {
            return "minimal"
        }
        return "low"
    }
}
