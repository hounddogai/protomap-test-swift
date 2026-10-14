import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol plan score falls in.
    static func classifyCareProtocolPlan(_ score: Double) -> String {
        if score < 59.2 {
            return "critical"
        }
        if score < 70.6 {
            return "medium"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 26676.0, in order.
    static func careProtocolPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26676.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCareProtocolPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
