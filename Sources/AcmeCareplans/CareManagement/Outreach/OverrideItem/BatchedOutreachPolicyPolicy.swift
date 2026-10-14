import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched outreach policy score falls in.
    static func classifyBatchedOutreachPolicy(_ score: Double) -> String {
        if score < 8.7 {
            return "ok"
        }
        if score < 64.1 {
            return "minimal"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 62829.0, in order.
    static func batchedOutreachPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62829.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched outreach policy code in its canonical BOP- form.
    static func normalizeBatchedOutreachPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BOP-") {
            return clean
        }
        return "BOP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
