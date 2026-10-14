import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedBedBoardSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a batched bed board slot code in its canonical BBBS- form.
    static func normalizeBatchedBedBoardSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBBS-") {
            return clean
        }
        return "BBBS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedBedBoardSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 57977.0, in order.
    static func batchedBedBoardSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57977.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
