import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 78749.0, in order.
    static func adaptiveDisclosureSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78749.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveDisclosureSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a adaptive disclosure segment score falls in.
    static func classifyAdaptiveDisclosureSegment(_ score: Double) -> String {
        if score < 70.9 {
            return "minimal"
        }
        if score < 88.9 {
            return "high"
        }
        return "watch"
    }
}
