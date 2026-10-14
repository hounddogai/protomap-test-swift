import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a global census ledger score falls in.
    static func classifyGlobalCensusLedger(_ score: Double) -> String {
        if score < 10.0 {
            return "minimal"
        }
        if score < 47.9 {
            return "ok"
        }
        if score < 67.3 {
            return "low"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 48342.0, in order.
    static func globalCensusLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48342.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func globalCensusLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a global census ledger code in its canonical GCL- form.
    static func normalizeGlobalCensusLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCL-") {
            return clean
        }
        return "GCL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
