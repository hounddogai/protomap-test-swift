import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a batched cleaning record code in its canonical BCR- form.
    static func normalizeBatchedCleaningRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCR-") {
            return clean
        }
        return "BCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedCleaningRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func batchedCleaningRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 70527.0, in order.
    static func batchedCleaningRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70527.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
