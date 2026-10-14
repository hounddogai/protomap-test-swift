import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a fallback assessment manifest score falls in.
    static func classifyFallbackAssessmentManifest(_ score: Double) -> String {
        if score < 18.4 {
            return "medium"
        }
        if score < 51.3 {
            return "low"
        }
        if score < 63.6 {
            return "watch"
        }
        if score < 71.9 {
            return "ok"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 5017.0, in order.
    static func fallbackAssessmentManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5017.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeFallbackAssessmentManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
