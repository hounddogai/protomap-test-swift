import AcmePlatform
import Foundation

extension Consent {
    /// Puts a language milestone code in its canonical LM- form.
    static func normalizeLanguageMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LM-") {
            return clean
        }
        return "LM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func languageMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a language milestone score falls in.
    static func classifyLanguageMilestone(_ score: Double) -> String {
        if score < 58.3 {
            return "high"
        }
        if score < 79.0 {
            return "medium"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
