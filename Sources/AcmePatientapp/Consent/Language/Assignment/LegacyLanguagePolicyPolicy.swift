import AcmePlatform
import Foundation

extension Consent {
    /// Puts a legacy language policy code in its canonical LLP- form.
    static func normalizeLegacyLanguagePolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LLP-") {
            return clean
        }
        return "LLP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyLanguagePolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-language-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyLanguagePolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a legacy language policy score falls in.
    static func classifyLegacyLanguagePolicy(_ score: Double) -> String {
        if score < 38.4 {
            return "watch"
        }
        if score < 56.8 {
            return "ok"
        }
        if score < 78.1 {
            return "low"
        }
        if score < 86.4 {
            return "elevated"
        }
        return "medium"
    }
}
