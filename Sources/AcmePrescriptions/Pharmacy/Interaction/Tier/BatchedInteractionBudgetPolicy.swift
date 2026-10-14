import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a batched interaction budget code in its canonical BIB- form.
    static func normalizeBatchedInteractionBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BIB-") {
            return clean
        }
        return "BIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedInteractionBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func batchedInteractionBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
