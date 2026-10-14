import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 48916.0, in order.
    static func lenientChargeTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48916.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a lenient charge tier score falls in.
    static func classifyLenientChargeTier(_ score: Double) -> String {
        if score < 31.7 {
            return "elevated"
        }
        if score < 51.7 {
            return "minimal"
        }
        if score < 52.2 {
            return "low"
        }
        if score < 75.2 {
            return "medium"
        }
        return "watch"
    }

    static func lenientChargeTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func lenientChargeTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
