import AcmePlatform
import Foundation

extension Imaging {
    static func tieredCareProtocolLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 97023.0, in order.
    static func tieredCareProtocolLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97023.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a tiered care protocol ledger score falls in.
    static func classifyTieredCareProtocolLedger(_ score: Double) -> String {
        if score < 46.1 {
            return "low"
        }
        if score < 63.2 {
            return "critical"
        }
        if score < 75.8 {
            return "medium"
        }
        if score < 77.4 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a tiered care protocol ledger code in its canonical TCPL- form.
    static func normalizeTieredCareProtocolLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCPL-") {
            return clean
        }
        return "TCPL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
