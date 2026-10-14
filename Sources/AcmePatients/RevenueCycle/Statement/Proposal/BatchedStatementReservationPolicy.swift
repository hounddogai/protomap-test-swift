import AcmePlatform
import Foundation

extension RevenueCycle {
    static func batchedStatementReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a batched statement reservation code in its canonical BSR- form.
    static func normalizeBatchedStatementReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSR-") {
            return clean
        }
        return "BSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 93695.0, in order.
    static func batchedStatementReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93695.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedStatementReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
