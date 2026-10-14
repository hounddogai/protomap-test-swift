import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol draft score falls in.
    static func classifyCareProtocolDraft(_ score: Double) -> String {
        if score < 52.2 {
            return "low"
        }
        if score < 53.4 {
            return "critical"
        }
        if score < 54.7 {
            return "medium"
        }
        if score < 72.0 {
            return "minimal"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 39964.0, in order.
    static func careProtocolDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39964.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCareProtocolDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
