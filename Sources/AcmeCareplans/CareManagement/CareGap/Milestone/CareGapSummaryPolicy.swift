import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeCareGapSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 33607.0, in order.
    static func careGapSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33607.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a care gap summary code in its canonical CGS- form.
    static func normalizeCareGapSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGS-") {
            return clean
        }
        return "CGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
