import AcmePlatform
import Foundation

extension Labs {
    /// Puts a rolling accession reservation code in its canonical RAR- form.
    static func normalizeRollingAccessionReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAR-") {
            return clean
        }
        return "RAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling accession reservation score falls in.
    static func classifyRollingAccessionReservation(_ score: Double) -> String {
        if score < 36.8 {
            return "high"
        }
        if score < 41.7 {
            return "elevated"
        }
        if score < 42.6 {
            return "minimal"
        }
        if score < 64.4 {
            return "critical"
        }
        return "watch"
    }

    static func rollingAccessionReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func rollingAccessionReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
