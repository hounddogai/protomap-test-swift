import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 23629.0, in order.
    static func careProtocolRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23629.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCareProtocolRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care protocol request score falls in.
    static func classifyCareProtocolRequest(_ score: Double) -> String {
        if score < 37.9 {
            return "critical"
        }
        if score < 40.3 {
            return "ok"
        }
        if score < 65.0 {
            return "high"
        }
        if score < 93.1 {
            return "elevated"
        }
        return "minimal"
    }
}
