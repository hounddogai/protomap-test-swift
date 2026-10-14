import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalFormularyPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func globalFormularyPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a global formulary preference code in its canonical GFP- form.
    static func normalizeGlobalFormularyPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GFP-") {
            return clean
        }
        return "GFP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
