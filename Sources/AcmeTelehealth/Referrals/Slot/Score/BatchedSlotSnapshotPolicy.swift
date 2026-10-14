import AcmePlatform
import Foundation

extension Referrals {
    static func batchedSlotSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a batched slot snapshot code in its canonical BSS- form.
    static func normalizeBatchedSlotSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSS-") {
            return clean
        }
        return "BSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 16584.0, in order.
    static func batchedSlotSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16584.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched slot snapshot score falls in.
    static func classifyBatchedSlotSnapshot(_ score: Double) -> String {
        if score < 13.7 {
            return "medium"
        }
        if score < 92.5 {
            return "ok"
        }
        if score < 95.3 {
            return "critical"
        }
        return "minimal"
    }
}
