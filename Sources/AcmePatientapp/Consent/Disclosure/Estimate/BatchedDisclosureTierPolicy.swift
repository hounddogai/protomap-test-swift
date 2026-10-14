import AcmePlatform
import Foundation

extension Consent {
    static func batchedDisclosureTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 87993.0, in order.
    static func batchedDisclosureTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87993.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched disclosure tier code in its canonical BDT- form.
    static func normalizeBatchedDisclosureTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BDT-") {
            return clean
        }
        return "BDT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
