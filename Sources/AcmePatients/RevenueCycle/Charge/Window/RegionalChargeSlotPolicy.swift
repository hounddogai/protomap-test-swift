import AcmePlatform
import Foundation

extension RevenueCycle {
    static func regionalChargeSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a regional charge slot score falls in.
    static func classifyRegionalChargeSlot(_ score: Double) -> String {
        if score < 19.9 {
            return "low"
        }
        if score < 67.5 {
            return "watch"
        }
        if score < 82.2 {
            return "critical"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 78402.0, in order.
    static func regionalChargeSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78402.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
