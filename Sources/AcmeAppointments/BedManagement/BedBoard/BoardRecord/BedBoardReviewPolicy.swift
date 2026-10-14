import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 96799.0, in order.
    static func bedBoardReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96799.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a bed board review score falls in.
    static func classifyBedBoardReview(_ score: Double) -> String {
        if score < 10.2 {
            return "watch"
        }
        if score < 43.0 {
            return "critical"
        }
        if score < 78.3 {
            return "medium"
        }
        return "high"
    }

    static func bedBoardReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
