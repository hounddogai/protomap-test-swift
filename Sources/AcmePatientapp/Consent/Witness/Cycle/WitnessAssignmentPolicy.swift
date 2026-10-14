import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a witness assignment score falls in.
    static func classifyWitnessAssignment(_ score: Double) -> String {
        if score < 24.4 {
            return "critical"
        }
        if score < 31.5 {
            return "elevated"
        }
        if score < 39.2 {
            return "high"
        }
        if score < 72.2 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 50794.0, in order.
    static func witnessAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50794.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func witnessAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeWitnessAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
