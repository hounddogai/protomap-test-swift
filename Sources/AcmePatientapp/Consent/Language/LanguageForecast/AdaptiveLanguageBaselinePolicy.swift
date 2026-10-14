import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveLanguageBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-language-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a adaptive language baseline score falls in.
    static func classifyAdaptiveLanguageBaseline(_ score: Double) -> String {
        if score < 15.6 {
            return "critical"
        }
        if score < 81.3 {
            return "elevated"
        }
        if score < 83.8 {
            return "high"
        }
        if score < 84.9 {
            return "low"
        }
        return "watch"
    }

    /// Puts a adaptive language baseline code in its canonical ALB- form.
    static func normalizeAdaptiveLanguageBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ALB-") {
            return clean
        }
        return "ALB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
