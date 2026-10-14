import AcmePlatform
import Foundation

extension Labs {
    /// Puts a legacy result forecast code in its canonical LRF- form.
    static func normalizeLegacyResultForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRF-") {
            return clean
        }
        return "LRF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyResultForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
