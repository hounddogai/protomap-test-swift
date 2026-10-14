import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a manual formulary assignment score falls in.
    static func classifyManualFormularyAssignment(_ score: Double) -> String {
        if score < 24.7 {
            return "critical"
        }
        if score < 53.0 {
            return "watch"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 51436.0, in order.
    static func manualFormularyAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51436.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeManualFormularyAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
