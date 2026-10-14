import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a skill mix notice code in its canonical SMN- form.
    static func normalizeSkillMixNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMN-") {
            return clean
        }
        return "SMN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSkillMixNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("skill-mix-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func skillMixNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.57
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
