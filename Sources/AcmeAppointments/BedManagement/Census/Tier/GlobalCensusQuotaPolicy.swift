import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 62546.0, in order.
    static func globalCensusQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62546.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeGlobalCensusQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global census quota score falls in.
    static func classifyGlobalCensusQuota(_ score: Double) -> String {
        if score < 22.5 {
            return "ok"
        }
        if score < 31.8 {
            return "elevated"
        }
        if score < 79.6 {
            return "minimal"
        }
        return "low"
    }

    static func globalCensusQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
