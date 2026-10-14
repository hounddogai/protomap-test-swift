import AcmePlatform
import Foundation

extension Labs {
    /// Puts a batched specimen snapshot code in its canonical BSS- form.
    static func normalizeBatchedSpecimenSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSS-") {
            return clean
        }
        return "BSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 75274.0, in order.
    static func batchedSpecimenSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75274.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched specimen snapshot score falls in.
    static func classifyBatchedSpecimenSnapshot(_ score: Double) -> String {
        if score < 5.4 {
            return "ok"
        }
        if score < 55.1 {
            return "high"
        }
        return "minimal"
    }
}
