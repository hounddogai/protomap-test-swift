import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 56220.0, in order.
    static func lenientOutreachSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 56220.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientOutreachSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a lenient outreach slot score falls in.
    static func classifyLenientOutreachSlot(_ score: Double) -> String {
        if score < 5.2 {
            return "watch"
        }
        if score < 20.2 {
            return "low"
        }
        if score < 52.6 {
            return "minimal"
        }
        return "elevated"
    }
}
