import AcmePlatform
import Foundation

extension Consent {
    /// Puts a weighted language request code in its canonical WLR- form.
    static func normalizeWeightedLanguageRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WLR-") {
            return clean
        }
        return "WLR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a weighted language request score falls in.
    static func classifyWeightedLanguageRequest(_ score: Double) -> String {
        if score < 5.3 {
            return "elevated"
        }
        if score < 11.2 {
            return "high"
        }
        if score < 29.8 {
            return "medium"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedLanguageRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-language-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
