import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a cleaning ledger code in its canonical CL- form.
    static func normalizeCleaningLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CL-") {
            return clean
        }
        return "CL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 42450.0, in order.
    static func cleaningLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42450.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a cleaning ledger score falls in.
    static func classifyCleaningLedger(_ score: Double) -> String {
        if score < 19.7 {
            return "low"
        }
        if score < 79.2 {
            return "medium"
        }
        if score < 96.1 {
            return "high"
        }
        return "critical"
    }

    static func mergeCleaningLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
