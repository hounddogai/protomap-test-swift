import AcmePlatform
import Foundation

extension CareManagement {
    static func seasonalRiskScorePreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a seasonal risk score preference code in its canonical SRSP- form.
    static func normalizeSeasonalRiskScorePreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRSP-") {
            return clean
        }
        return "SRSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
