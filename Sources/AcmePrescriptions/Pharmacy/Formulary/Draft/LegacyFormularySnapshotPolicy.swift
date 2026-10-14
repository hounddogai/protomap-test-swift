import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeLegacyFormularySnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func legacyFormularySnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a legacy formulary snapshot score falls in.
    static func classifyLegacyFormularySnapshot(_ score: Double) -> String {
        if score < 29.7 {
            return "ok"
        }
        if score < 41.6 {
            return "minimal"
        }
        if score < 45.3 {
            return "critical"
        }
        if score < 77.5 {
            return "high"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 64115.0, in order.
    static func legacyFormularySnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64115.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
