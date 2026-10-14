import AcmePlatform
import Foundation

extension ClinicalOps {
    static func seasonalOrderSetProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 16845.0, in order.
    static func seasonalOrderSetProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16845.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal order set profile code in its canonical SOSP- form.
    static func normalizeSeasonalOrderSetProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOSP-") {
            return clean
        }
        return "SOSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
