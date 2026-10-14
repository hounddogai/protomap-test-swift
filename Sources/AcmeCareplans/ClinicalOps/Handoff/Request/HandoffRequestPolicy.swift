import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a handoff request score falls in.
    static func classifyHandoffRequest(_ score: Double) -> String {
        if score < 30.3 {
            return "high"
        }
        if score < 40.1 {
            return "ok"
        }
        if score < 65.0 {
            return "elevated"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 53531.0, in order.
    static func handoffRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53531.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeHandoffRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
