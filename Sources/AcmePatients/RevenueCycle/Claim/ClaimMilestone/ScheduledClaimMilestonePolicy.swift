import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledClaimMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-claim-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled claim milestone code in its canonical SCM- form.
    static func normalizeScheduledClaimMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCM-") {
            return clean
        }
        return "SCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeScheduledClaimMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
