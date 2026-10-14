import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a regional study snapshot score falls in.
    static func classifyRegionalStudySnapshot(_ score: Double) -> String {
        if score < 12.4 {
            return "low"
        }
        if score < 14.1 {
            return "ok"
        }
        if score < 43.1 {
            return "critical"
        }
        if score < 82.0 {
            return "elevated"
        }
        return "high"
    }

    static func regionalStudySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a regional study snapshot code in its canonical RSS- form.
    static func normalizeRegionalStudySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSS-") {
            return clean
        }
        return "RSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
