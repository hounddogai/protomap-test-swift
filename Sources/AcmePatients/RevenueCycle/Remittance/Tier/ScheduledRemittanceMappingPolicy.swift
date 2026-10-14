import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a scheduled remittance mapping code in its canonical SRM- form.
    static func normalizeScheduledRemittanceMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRM-") {
            return clean
        }
        return "SRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled remittance mapping score falls in.
    static func classifyScheduledRemittanceMapping(_ score: Double) -> String {
        if score < 23.7 {
            return "minimal"
        }
        if score < 40.2 {
            return "elevated"
        }
        if score < 40.8 {
            return "watch"
        }
        if score < 81.6 {
            return "high"
        }
        return "medium"
    }

    static func scheduledRemittanceMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func scheduledRemittanceMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
