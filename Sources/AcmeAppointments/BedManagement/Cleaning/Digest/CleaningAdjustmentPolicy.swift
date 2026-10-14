import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeCleaningAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 19377.0, in order.
    static func cleaningAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19377.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a cleaning adjustment code in its canonical CA- form.
    static func normalizeCleaningAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CA-") {
            return clean
        }
        return "CA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
