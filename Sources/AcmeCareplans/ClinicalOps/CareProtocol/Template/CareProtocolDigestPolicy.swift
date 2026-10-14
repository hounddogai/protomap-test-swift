import AcmePlatform
import Foundation

extension ClinicalOps {
    static func careProtocolDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func mergeCareProtocolDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 39517.0, in order.
    static func careProtocolDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39517.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care protocol digest score falls in.
    static func classifyCareProtocolDigest(_ score: Double) -> String {
        if score < 13.4 {
            return "elevated"
        }
        if score < 76.2 {
            return "critical"
        }
        if score < 84.0 {
            return "high"
        }
        return "low"
    }
}
