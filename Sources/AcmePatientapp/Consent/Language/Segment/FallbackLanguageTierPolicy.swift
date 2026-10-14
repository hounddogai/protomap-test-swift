import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackLanguageTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-language-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback language tier score falls in.
    static func classifyFallbackLanguageTier(_ score: Double) -> String {
        if score < 19.9 {
            return "low"
        }
        if score < 61.9 {
            return "elevated"
        }
        if score < 77.2 {
            return "watch"
        }
        if score < 93.2 {
            return "high"
        }
        return "critical"
    }

    /// Puts a fallback language tier code in its canonical FLT- form.
    static func normalizeFallbackLanguageTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FLT-") {
            return clean
        }
        return "FLT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackLanguageTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
