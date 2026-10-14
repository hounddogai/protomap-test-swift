import AcmePlatform
import Foundation

extension Labs {
    /// Puts a scheduled panel group code in its canonical SPG- form.
    static func normalizeScheduledPanelGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPG-") {
            return clean
        }
        return "SPG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledPanelGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
