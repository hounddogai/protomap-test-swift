import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 27342.0, in order.
    static func manualHandoffAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27342.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual handoff assignment score falls in.
    static func classifyManualHandoffAssignment(_ score: Double) -> String {
        if score < 18.1 {
            return "elevated"
        }
        if score < 23.7 {
            return "watch"
        }
        return "minimal"
    }
}
