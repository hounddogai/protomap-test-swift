import AcmePlatform
import Foundation

extension Consent {
    /// Puts a default disclosure segment code in its canonical DDS- form.
    static func normalizeDefaultDisclosureSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DDS-") {
            return clean
        }
        return "DDS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultDisclosureSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
