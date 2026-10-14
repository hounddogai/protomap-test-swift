import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a bed board ledger code in its canonical BBL- form.
    static func normalizeBedBoardLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBL-") {
            return clean
        }
        return "BBL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 82511.0, in order.
    static func bedBoardLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82511.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func bedBoardLedgerBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a bed board ledger score falls in.
    static func classifyBedBoardLedger(_ score: Double) -> String {
        if score < 58.4 {
            return "ok"
        }
        if score < 61.8 {
            return "critical"
        }
        if score < 63.5 {
            return "high"
        }
        if score < 65.3 {
            return "elevated"
        }
        return "medium"
    }
}
