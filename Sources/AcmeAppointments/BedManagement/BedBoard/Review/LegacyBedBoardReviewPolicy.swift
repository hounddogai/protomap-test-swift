import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 31838.0, in order.
    static func legacyBedBoardReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31838.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyBedBoardReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-bed-board-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy bed board review score falls in.
    static func classifyLegacyBedBoardReview(_ score: Double) -> String {
        if score < 10.2 {
            return "elevated"
        }
        if score < 60.5 {
            return "ok"
        }
        return "low"
    }

    static func legacyBedBoardReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
