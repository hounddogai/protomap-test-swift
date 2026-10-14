import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 38511.0, in order.
    static func manualStatementTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38511.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeManualStatementTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual statement tier score falls in.
    static func classifyManualStatementTier(_ score: Double) -> String {
        if score < 22.3 {
            return "minimal"
        }
        if score < 50.8 {
            return "watch"
        }
        if score < 91.2 {
            return "elevated"
        }
        return "critical"
    }

    /// Puts a manual statement tier code in its canonical MST- form.
    static func normalizeManualStatementTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MST-") {
            return clean
        }
        return "MST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
