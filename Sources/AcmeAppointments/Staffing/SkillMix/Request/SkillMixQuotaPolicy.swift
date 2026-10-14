import AcmePlatform
import Foundation

extension Staffing {
    static func skillMixQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.25
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a skill mix quota code in its canonical SMQ- form.
    static func normalizeSkillMixQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMQ-") {
            return clean
        }
        return "SMQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a skill mix quota score falls in.
    static func classifySkillMixQuota(_ score: Double) -> String {
        if score < 7.1 {
            return "ok"
        }
        if score < 47.2 {
            return "high"
        }
        if score < 68.0 {
            return "watch"
        }
        if score < 90.7 {
            return "medium"
        }
        return "minimal"
    }
}
