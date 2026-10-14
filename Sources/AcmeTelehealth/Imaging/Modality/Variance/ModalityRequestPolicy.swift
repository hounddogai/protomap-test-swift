import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 64051.0, in order.
    static func modalityRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64051.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeModalityRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a modality request score falls in.
    static func classifyModalityRequest(_ score: Double) -> String {
        if score < 32.8 {
            return "critical"
        }
        if score < 74.4 {
            return "ok"
        }
        if score < 88.6 {
            return "minimal"
        }
        if score < 97.7 {
            return "elevated"
        }
        return "medium"
    }
}
