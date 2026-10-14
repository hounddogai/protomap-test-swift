import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a tiered recall summary code in its canonical TRS- form.
    static func normalizeTieredRecallSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRS-") {
            return clean
        }
        return "TRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredRecallSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
