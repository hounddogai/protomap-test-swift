import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a bed board tier score falls in.
    static func classifyBedBoardTier(_ score: Double) -> String {
        if score < 8.4 {
            return "watch"
        }
        if score < 12.6 {
            return "medium"
        }
        if score < 22.7 {
            return "critical"
        }
        if score < 51.1 {
            return "low"
        }
        return "elevated"
    }

    static func bedBoardTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.5
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBedBoardTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("bed-board-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func bedBoardTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
