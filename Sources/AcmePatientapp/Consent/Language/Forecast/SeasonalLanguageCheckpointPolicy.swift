import AcmePlatform
import Foundation

extension Consent {
    static func seasonalLanguageCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a seasonal language checkpoint code in its canonical SLC- form.
    static func normalizeSeasonalLanguageCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SLC-") {
            return clean
        }
        return "SLC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 36833.0, in order.
    static func seasonalLanguageCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36833.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
