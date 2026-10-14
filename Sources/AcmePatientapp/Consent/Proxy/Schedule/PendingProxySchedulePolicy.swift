import AcmePlatform
import Foundation

extension Consent {
    /// Puts a pending proxy schedule code in its canonical PPS- form.
    static func normalizePendingProxyScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPS-") {
            return clean
        }
        return "PPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingProxyScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
