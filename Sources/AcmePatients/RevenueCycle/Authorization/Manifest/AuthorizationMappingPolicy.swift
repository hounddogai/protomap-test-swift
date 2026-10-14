import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a authorization mapping score falls in.
    static func classifyAuthorizationMapping(_ score: Double) -> String {
        if score < 62.6 {
            return "low"
        }
        if score < 62.8 {
            return "elevated"
        }
        if score < 63.2 {
            return "watch"
        }
        return "high"
    }

    static func authorizationMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a authorization mapping code in its canonical AM- form.
    static func normalizeAuthorizationMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AM-") {
            return clean
        }
        return "AM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func authorizationMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
