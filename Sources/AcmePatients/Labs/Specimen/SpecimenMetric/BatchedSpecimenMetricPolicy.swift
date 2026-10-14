import AcmePlatform
import Foundation

extension Labs {
    /// Puts a batched specimen metric code in its canonical BSM- form.
    static func normalizeBatchedSpecimenMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSM-") {
            return clean
        }
        return "BSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 62981.0, in order.
    static func batchedSpecimenMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62981.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedSpecimenMetricSpan(_ start: Int, end: Int) -> Int {
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
