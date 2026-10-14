import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 37243.0, in order.
    static func formularyBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37243.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a formulary batch score falls in.
    static func classifyFormularyBatch(_ score: Double) -> String {
        if score < 22.1 {
            return "elevated"
        }
        if score < 49.3 {
            return "ok"
        }
        return "critical"
    }

    /// Puts a formulary batch code in its canonical FB- form.
    static func normalizeFormularyBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FB-") {
            return clean
        }
        return "FB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func formularyBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
