import AcmePlatform
import Foundation

extension BedManagement {
    static func cappedBedBoardDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func cappedBedBoardDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a capped bed board digest score falls in.
    static func classifyCappedBedBoardDigest(_ score: Double) -> String {
        if score < 23.7 {
            return "ok"
        }
        if score < 34.9 {
            return "critical"
        }
        if score < 61.3 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a capped bed board digest code in its canonical CBBD- form.
    static func normalizeCappedBedBoardDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CBBD-") {
            return clean
        }
        return "CBBD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
