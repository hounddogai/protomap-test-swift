import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a capped result segment score falls in.
    static func classifyCappedResultSegment(_ score: Double) -> String {
        if score < 57.4 {
            return "high"
        }
        if score < 75.4 {
            return "medium"
        }
        if score < 90.1 {
            return "low"
        }
        if score < 95.2 {
            return "critical"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 66740.0, in order.
    static func cappedResultSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66740.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
