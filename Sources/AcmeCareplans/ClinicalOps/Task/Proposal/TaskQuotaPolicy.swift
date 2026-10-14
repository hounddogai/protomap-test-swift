import AcmePlatform
import Foundation

extension ClinicalOps {
    static func taskQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 70569.0, in order.
    static func taskQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70569.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a task quota code in its canonical TQ- form.
    static func normalizeTaskQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TQ-") {
            return clean
        }
        return "TQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
