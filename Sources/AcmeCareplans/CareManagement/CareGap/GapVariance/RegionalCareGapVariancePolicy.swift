import AcmePlatform
import Foundation

extension CareManagement {
    static func regionalCareGapVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a regional care gap variance code in its canonical RCGV- form.
    static func normalizeRegionalCareGapVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCGV-") {
            return clean
        }
        return "RCGV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
