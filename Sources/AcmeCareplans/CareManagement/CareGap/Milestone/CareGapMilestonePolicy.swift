import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap milestone score falls in.
    static func classifyCareGapMilestone(_ score: Double) -> String {
        if score < 36.0 {
            return "low"
        }
        if score < 91.2 {
            return "medium"
        }
        return "elevated"
    }

    static func careGapMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.32
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func careGapMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
