import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a pending census record code in its canonical PCR- form.
    static func normalizePendingCensusRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCR-") {
            return clean
        }
        return "PCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingCensusRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a pending census record score falls in.
    static func classifyPendingCensusRecord(_ score: Double) -> String {
        if score < 13.6 {
            return "medium"
        }
        if score < 52.1 {
            return "high"
        }
        if score < 99.1 {
            return "watch"
        }
        return "low"
    }
}
