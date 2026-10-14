import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryCareGapOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 15658.0, in order.
    static func primaryCareGapOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15658.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary care gap override score falls in.
    static func classifyPrimaryCareGapOverride(_ score: Double) -> String {
        if score < 28.2 {
            return "minimal"
        }
        if score < 48.3 {
            return "low"
        }
        if score < 55.6 {
            return "critical"
        }
        return "elevated"
    }
}
