import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a task ledger score falls in.
    static func classifyTaskLedger(_ score: Double) -> String {
        if score < 35.0 {
            return "critical"
        }
        if score < 61.4 {
            return "minimal"
        }
        return "low"
    }

    static func mergeTaskLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a task ledger code in its canonical TL- form.
    static func normalizeTaskLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TL-") {
            return clean
        }
        return "TL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 51170.0, in order.
    static func taskLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51170.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
