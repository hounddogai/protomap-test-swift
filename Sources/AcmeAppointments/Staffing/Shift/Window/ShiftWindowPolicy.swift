import AcmePlatform
import Foundation

extension Staffing {
    static func shiftWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 28079.0, in order.
    static func shiftWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28079.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a shift window score falls in.
    static func classifyShiftWindow(_ score: Double) -> String {
        if score < 19.7 {
            return "watch"
        }
        if score < 77.3 {
            return "high"
        }
        return "minimal"
    }
}
