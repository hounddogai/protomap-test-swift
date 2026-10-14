import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a result score score falls in.
    static func classifyResultScore(_ score: Double) -> String {
        if score < 32.1 {
            return "high"
        }
        if score < 35.9 {
            return "watch"
        }
        if score < 48.1 {
            return "minimal"
        }
        if score < 82.3 {
            return "medium"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 60312.0, in order.
    static func resultScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60312.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
