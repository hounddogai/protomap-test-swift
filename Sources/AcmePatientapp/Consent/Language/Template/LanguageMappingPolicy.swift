import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func languageMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.65
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a language mapping score falls in.
    static func classifyLanguageMapping(_ score: Double) -> String {
        if score < 20.3 {
            return "medium"
        }
        if score < 49.6 {
            return "watch"
        }
        if score < 58.3 {
            return "critical"
        }
        if score < 76.6 {
            return "minimal"
        }
        return "elevated"
    }
}
