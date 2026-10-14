import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledPriorityScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a scheduled priority score code in its canonical SPS- form.
    static func normalizeScheduledPriorityScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPS-") {
            return clean
        }
        return "SPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
