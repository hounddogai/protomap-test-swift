import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a rounding claim code in its canonical RC- form.
    static func normalizeRoundingClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RC-") {
            return clean
        }
        return "RC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func roundingClaimSpan(_ start: Int, end: Int) -> Int {
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
