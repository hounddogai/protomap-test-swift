import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 93331.0, in order.
    static func primaryClosureAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93331.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary closure assignment score falls in.
    static func classifyPrimaryClosureAssignment(_ score: Double) -> String {
        if score < 3.3 {
            return "ok"
        }
        if score < 23.9 {
            return "high"
        }
        if score < 68.5 {
            return "elevated"
        }
        return "low"
    }
}
