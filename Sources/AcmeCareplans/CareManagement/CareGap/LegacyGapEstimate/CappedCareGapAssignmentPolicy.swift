import AcmePlatform
import Foundation

extension CareManagement {
    static func cappedCareGapAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeCappedCareGapAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped care gap assignment score falls in.
    static func classifyCappedCareGapAssignment(_ score: Double) -> String {
        if score < 9.4 {
            return "ok"
        }
        if score < 26.6 {
            return "elevated"
        }
        if score < 50.1 {
            return "medium"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 78545.0, in order.
    static func cappedCareGapAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 78545.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
