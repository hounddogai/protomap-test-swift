import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 11149.0, in order.
    static func batchedCourierBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11149.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched courier batch code in its canonical BCB- form.
    static func normalizeBatchedCourierBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCB-") {
            return clean
        }
        return "BCB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
