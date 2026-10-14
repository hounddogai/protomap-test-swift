import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a fallback specimen request score falls in.
    static func classifyFallbackSpecimenRequest(_ score: Double) -> String {
        if score < 14.1 {
            return "ok"
        }
        if score < 36.8 {
            return "elevated"
        }
        return "minimal"
    }

    static func fallbackSpecimenRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 54791.0, in order.
    static func fallbackSpecimenRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54791.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
