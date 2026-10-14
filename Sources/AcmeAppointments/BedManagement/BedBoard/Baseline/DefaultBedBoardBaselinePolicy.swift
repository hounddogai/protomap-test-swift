import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a default bed board baseline score falls in.
    static func classifyDefaultBedBoardBaseline(_ score: Double) -> String {
        if score < 83.3 {
            return "high"
        }
        if score < 91.4 {
            return "minimal"
        }
        if score < 92.2 {
            return "watch"
        }
        return "medium"
    }

    static func defaultBedBoardBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultBedBoardBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-bed-board-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultBedBoardBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
