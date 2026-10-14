import AcmePlatform
import Foundation

extension Labs {
    static func specimenScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a specimen score score falls in.
    static func classifySpecimenScore(_ score: Double) -> String {
        if score < 3.3 {
            return "ok"
        }
        if score < 6.6 {
            return "watch"
        }
        if score < 38.3 {
            return "elevated"
        }
        if score < 68.1 {
            return "medium"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 7554.0, in order.
    static func specimenScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7554.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
