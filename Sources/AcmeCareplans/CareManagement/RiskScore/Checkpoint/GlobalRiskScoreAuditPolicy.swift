import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a global risk score audit score falls in.
    static func classifyGlobalRiskScoreAudit(_ score: Double) -> String {
        if score < 15.5 {
            return "critical"
        }
        if score < 47.6 {
            return "ok"
        }
        if score < 87.9 {
            return "minimal"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 2101.0, in order.
    static func globalRiskScoreAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2101.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeGlobalRiskScoreAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
