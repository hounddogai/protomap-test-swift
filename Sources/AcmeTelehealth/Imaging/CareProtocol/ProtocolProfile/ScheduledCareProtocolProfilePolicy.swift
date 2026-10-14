import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledCareProtocolProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Puts a scheduled care protocol profile code in its canonical SCPP- form.
    static func normalizeScheduledCareProtocolProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPP-") {
            return clean
        }
        return "SCPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
