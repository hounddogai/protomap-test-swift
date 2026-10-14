import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall digest code in its canonical RD- form.
    static func normalizeRecallDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RD-") {
            return clean
        }
        return "RD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func recallDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 92757.0, in order.
    static func recallDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92757.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
