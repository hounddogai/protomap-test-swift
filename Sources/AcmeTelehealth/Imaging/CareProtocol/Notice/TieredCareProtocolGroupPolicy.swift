import AcmePlatform
import Foundation

extension Imaging {
    static func tieredCareProtocolGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a tiered care protocol group code in its canonical TCPG- form.
    static func normalizeTieredCareProtocolGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCPG-") {
            return clean
        }
        return "TCPG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a tiered care protocol group score falls in.
    static func classifyTieredCareProtocolGroup(_ score: Double) -> String {
        if score < 25.8 {
            return "minimal"
        }
        if score < 58.4 {
            return "high"
        }
        return "elevated"
    }

    static func tieredCareProtocolGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
