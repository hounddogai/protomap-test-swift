import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a regional bed board allocation score falls in.
    static func classifyRegionalBedBoardAllocation(_ score: Double) -> String {
        if score < 34.3 {
            return "elevated"
        }
        if score < 44.9 {
            return "watch"
        }
        if score < 45.8 {
            return "low"
        }
        if score < 78.7 {
            return "critical"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalBedBoardAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-bed-board-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalBedBoardAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 46831.0, in order.
    static func regionalBedBoardAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46831.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
