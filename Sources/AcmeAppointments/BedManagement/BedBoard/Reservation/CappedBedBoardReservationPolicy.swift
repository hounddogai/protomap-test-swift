import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeCappedBedBoardReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped bed board reservation score falls in.
    static func classifyCappedBedBoardReservation(_ score: Double) -> String {
        if score < 25.3 {
            return "medium"
        }
        if score < 38.6 {
            return "low"
        }
        if score < 90.2 {
            return "high"
        }
        if score < 92.2 {
            return "ok"
        }
        return "minimal"
    }

    /// Puts a capped bed board reservation code in its canonical CBBR- form.
    static func normalizeCappedBedBoardReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CBBR-") {
            return clean
        }
        return "CBBR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedBedBoardReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
