import AcmePlatform
import Foundation

extension Pharmacy {
    static func interactionVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Puts a interaction variance code in its canonical IV- form.
    static func normalizeInteractionVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IV-") {
            return clean
        }
        return "IV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
