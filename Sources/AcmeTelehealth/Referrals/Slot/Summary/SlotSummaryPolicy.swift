import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 30239.0, in order.
    static func slotSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30239.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a slot summary score falls in.
    static func classifySlotSummary(_ score: Double) -> String {
        if score < 45.1 {
            return "high"
        }
        if score < 54.5 {
            return "ok"
        }
        if score < 93.5 {
            return "medium"
        }
        return "watch"
    }

    /// Puts a slot summary code in its canonical SS- form.
    static func normalizeSlotSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SS-") {
            return clean
        }
        return "SS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSlotSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
