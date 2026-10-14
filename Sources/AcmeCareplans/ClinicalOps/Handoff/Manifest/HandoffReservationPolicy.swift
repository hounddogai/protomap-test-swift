import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a handoff reservation code in its canonical HR- form.
    static func normalizeHandoffReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HR-") {
            return clean
        }
        return "HR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a handoff reservation score falls in.
    static func classifyHandoffReservation(_ score: Double) -> String {
        if score < 15.8 {
            return "elevated"
        }
        if score < 43.1 {
            return "minimal"
        }
        if score < 75.7 {
            return "medium"
        }
        return "watch"
    }

    static func handoffReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func mergeHandoffReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
