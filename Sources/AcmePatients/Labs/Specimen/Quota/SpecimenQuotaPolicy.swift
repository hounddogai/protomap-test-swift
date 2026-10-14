import AcmePlatform
import Foundation

extension Labs {
    static func mergeSpecimenQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func specimenQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 65327.0, in order.
    static func specimenQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65327.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a specimen quota score falls in.
    static func classifySpecimenQuota(_ score: Double) -> String {
        if score < 65.3 {
            return "elevated"
        }
        if score < 66.6 {
            return "minimal"
        }
        if score < 77.2 {
            return "critical"
        }
        return "low"
    }
}
