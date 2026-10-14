import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a witness segment score falls in.
    static func classifyWitnessSegment(_ score: Double) -> String {
        if score < 8.6 {
            return "critical"
        }
        if score < 30.9 {
            return "elevated"
        }
        return "watch"
    }

    static func witnessSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 19295.0, in order.
    static func witnessSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19295.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func witnessSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
