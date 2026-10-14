import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a capped network schedule score falls in.
    static func classifyCappedNetworkSchedule(_ score: Double) -> String {
        if score < 34.1 {
            return "medium"
        }
        if score < 51.2 {
            return "elevated"
        }
        if score < 54.2 {
            return "critical"
        }
        if score < 90.7 {
            return "watch"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 28905.0, in order.
    static func cappedNetworkScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 28905.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedNetworkScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func cappedNetworkScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
