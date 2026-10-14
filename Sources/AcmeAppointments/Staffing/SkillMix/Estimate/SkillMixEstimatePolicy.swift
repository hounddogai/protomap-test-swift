import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a skill mix estimate code in its canonical SME- form.
    static func normalizeSkillMixEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SME-") {
            return clean
        }
        return "SME-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func skillMixEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
