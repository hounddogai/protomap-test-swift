import AcmePlatform
import Foundation

extension Consent {
    static func weightedConsentFormRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a weighted consent form rollup code in its canonical WCFR- form.
    static func normalizeWeightedConsentFormRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCFR-") {
            return clean
        }
        return "WCFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
