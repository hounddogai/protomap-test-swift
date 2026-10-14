import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 35615.0, in order.
    static func cappedPanelBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35615.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped panel budget score falls in.
    static func classifyCappedPanelBudget(_ score: Double) -> String {
        if score < 2.2 {
            return "watch"
        }
        if score < 32.3 {
            return "minimal"
        }
        if score < 37.8 {
            return "low"
        }
        if score < 61.5 {
            return "elevated"
        }
        return "medium"
    }
}
