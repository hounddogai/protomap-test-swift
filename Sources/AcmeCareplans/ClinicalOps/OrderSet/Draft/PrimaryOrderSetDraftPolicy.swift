import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergePrimaryOrderSetDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func primaryOrderSetDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 86015.0, in order.
    static func primaryOrderSetDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 86015.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary order set draft score falls in.
    static func classifyPrimaryOrderSetDraft(_ score: Double) -> String {
        if score < 23.6 {
            return "minimal"
        }
        if score < 68.3 {
            return "elevated"
        }
        if score < 88.2 {
            return "medium"
        }
        if score < 95.7 {
            return "watch"
        }
        return "high"
    }
}
