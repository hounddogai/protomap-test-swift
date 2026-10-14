import AcmePlatform
import Foundation

extension Pharmacy {
    static func weightedInteractionRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a weighted interaction record code in its canonical WIR- form.
    static func normalizeWeightedInteractionRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WIR-") {
            return clean
        }
        return "WIR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
