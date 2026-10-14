import AcmePlatform
import Foundation

extension Imaging {
    static func studyDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a study digest score falls in.
    static func classifyStudyDigest(_ score: Double) -> String {
        if score < 18.5 {
            return "watch"
        }
        if score < 32.0 {
            return "elevated"
        }
        if score < 59.7 {
            return "medium"
        }
        return "low"
    }

    /// Puts a study digest code in its canonical SD- form.
    static func normalizeStudyDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SD-") {
            return clean
        }
        return "SD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
