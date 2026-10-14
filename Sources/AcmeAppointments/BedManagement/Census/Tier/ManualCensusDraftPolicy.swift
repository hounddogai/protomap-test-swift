import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeManualCensusDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual census draft code in its canonical MCD- form.
    static func normalizeManualCensusDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCD-") {
            return clean
        }
        return "MCD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 39368.0, in order.
    static func manualCensusDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39368.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
