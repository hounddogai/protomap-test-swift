import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledCareProtocolSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a scheduled care protocol summary code in its canonical SCPS- form.
    static func normalizeScheduledCareProtocolSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPS-") {
            return clean
        }
        return "SCPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
