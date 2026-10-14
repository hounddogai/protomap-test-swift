import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a manual specimen segment score falls in.
    static func classifyManualSpecimenSegment(_ score: Double) -> String {
        if score < 20.0 {
            return "ok"
        }
        if score < 83.2 {
            return "watch"
        }
        if score < 83.6 {
            return "low"
        }
        return "elevated"
    }

    /// Puts a manual specimen segment code in its canonical MSS- form.
    static func normalizeManualSpecimenSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MSS-") {
            return clean
        }
        return "MSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualSpecimenSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func manualSpecimenSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.49
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
