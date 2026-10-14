import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen bundle score falls in.
    static func classifySpecimenBundle(_ score: Double) -> String {
        if score < 27.9 {
            return "medium"
        }
        if score < 77.7 {
            return "critical"
        }
        if score < 81.7 {
            return "high"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 92470.0, in order.
    static func specimenBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92470.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
