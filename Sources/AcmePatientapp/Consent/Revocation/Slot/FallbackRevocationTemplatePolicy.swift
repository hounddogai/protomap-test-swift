import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackRevocationTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-revocation-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback revocation template score falls in.
    static func classifyFallbackRevocationTemplate(_ score: Double) -> String {
        if score < 15.1 {
            return "critical"
        }
        if score < 19.9 {
            return "medium"
        }
        if score < 26.5 {
            return "elevated"
        }
        if score < 56.2 {
            return "low"
        }
        return "high"
    }

    /// Puts a fallback revocation template code in its canonical FRT- form.
    static func normalizeFallbackRevocationTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRT-") {
            return clean
        }
        return "FRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackRevocationTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
