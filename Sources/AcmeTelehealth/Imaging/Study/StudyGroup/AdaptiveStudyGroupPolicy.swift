import AcmePlatform
import Foundation

extension Imaging {
    static func adaptiveStudyGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a adaptive study group code in its canonical ASG- form.
    static func normalizeAdaptiveStudyGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ASG-") {
            return clean
        }
        return "ASG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive study group score falls in.
    static func classifyAdaptiveStudyGroup(_ score: Double) -> String {
        if score < 16.7 {
            return "minimal"
        }
        if score < 55.7 {
            return "watch"
        }
        return "critical"
    }

    static func adaptiveStudyGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
