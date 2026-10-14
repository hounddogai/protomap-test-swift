import AcmePlatform
import Foundation

extension Consent {
    /// Puts a lenient revocation summary code in its canonical LRS- form.
    static func normalizeLenientRevocationSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRS-") {
            return clean
        }
        return "LRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 87104.0, in order.
    static func lenientRevocationSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87104.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientRevocationSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
