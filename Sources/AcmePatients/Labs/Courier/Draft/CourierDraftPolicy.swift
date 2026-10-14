import AcmePlatform
import Foundation

extension Labs {
    static func courierDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a courier draft score falls in.
    static func classifyCourierDraft(_ score: Double) -> String {
        if score < 27.1 {
            return "watch"
        }
        if score < 74.7 {
            return "high"
        }
        if score < 83.5 {
            return "minimal"
        }
        if score < 97.1 {
            return "ok"
        }
        return "critical"
    }

    /// Puts a courier draft code in its canonical CD- form.
    static func normalizeCourierDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CD-") {
            return clean
        }
        return "CD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
