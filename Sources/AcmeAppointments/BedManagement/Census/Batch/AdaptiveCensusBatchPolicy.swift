import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveCensusBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 84767.0, in order.
    static func adaptiveCensusBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84767.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a adaptive census batch score falls in.
    static func classifyAdaptiveCensusBatch(_ score: Double) -> String {
        if score < 23.3 {
            return "watch"
        }
        if score < 65.5 {
            return "high"
        }
        return "low"
    }

    /// Puts a adaptive census batch code in its canonical ACB- form.
    static func normalizeAdaptiveCensusBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACB-") {
            return clean
        }
        return "ACB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
