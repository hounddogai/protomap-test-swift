import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptivePriorityMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-priority-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a adaptive priority milestone code in its canonical APM- form.
    static func normalizeAdaptivePriorityMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APM-") {
            return clean
        }
        return "APM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive priority milestone score falls in.
    static func classifyAdaptivePriorityMilestone(_ score: Double) -> String {
        if score < 33.1 {
            return "critical"
        }
        if score < 53.7 {
            return "medium"
        }
        if score < 70.8 {
            return "ok"
        }
        return "low"
    }

    static func mergeAdaptivePriorityMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
