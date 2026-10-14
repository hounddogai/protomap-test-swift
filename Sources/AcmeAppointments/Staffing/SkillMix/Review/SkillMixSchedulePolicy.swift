import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 36568.0, in order.
    static func skillMixScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36568.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a skill mix schedule score falls in.
    static func classifySkillMixSchedule(_ score: Double) -> String {
        if score < 5.7 {
            return "ok"
        }
        if score < 12.0 {
            return "elevated"
        }
        if score < 45.4 {
            return "minimal"
        }
        if score < 75.1 {
            return "low"
        }
        return "watch"
    }

    static func skillMixScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
