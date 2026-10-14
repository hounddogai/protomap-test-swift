import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 71733.0, in order.
    static func batchedBedBoardCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71733.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedBedBoardCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a batched bed board cycle code in its canonical BBBC- form.
    static func normalizeBatchedBedBoardCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBBC-") {
            return clean
        }
        return "BBBC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedBedBoardCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
