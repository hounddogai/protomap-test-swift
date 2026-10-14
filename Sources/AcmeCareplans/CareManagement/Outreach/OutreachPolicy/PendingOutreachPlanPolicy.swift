import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a pending outreach plan score falls in.
    static func classifyPendingOutreachPlan(_ score: Double) -> String {
        if score < 4.7 {
            return "low"
        }
        if score < 90.1 {
            return "high"
        }
        return "elevated"
    }

    static func pendingOutreachPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergePendingOutreachPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingOutreachPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-outreach-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
