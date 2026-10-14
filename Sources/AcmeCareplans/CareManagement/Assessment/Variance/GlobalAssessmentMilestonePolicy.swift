import AcmePlatform
import Foundation

extension CareManagement {
    static func globalAssessmentMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalAssessmentMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-assessment-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalAssessmentMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
