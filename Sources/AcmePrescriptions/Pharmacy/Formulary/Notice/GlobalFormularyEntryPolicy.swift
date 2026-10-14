import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalFormularyEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a global formulary entry code in its canonical GFE- form.
    static func normalizeGlobalFormularyEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GFE-") {
            return clean
        }
        return "GFE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
