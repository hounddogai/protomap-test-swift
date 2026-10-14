import AcmePlatform
import Foundation

extension Consent {
    static func regionalProxyManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    static func regionalProxyManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a regional proxy manifest score falls in.
    static func classifyRegionalProxyManifest(_ score: Double) -> String {
        if score < 23.1 {
            return "high"
        }
        if score < 58.7 {
            return "medium"
        }
        if score < 91.0 {
            return "minimal"
        }
        return "watch"
    }

    /// Puts a regional proxy manifest code in its canonical RPM- form.
    static func normalizeRegionalProxyManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPM-") {
            return clean
        }
        return "RPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
