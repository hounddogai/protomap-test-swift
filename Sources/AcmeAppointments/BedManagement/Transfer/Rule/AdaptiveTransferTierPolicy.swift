import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveTransferTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func adaptiveTransferTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a adaptive transfer tier code in its canonical ATT- form.
    static func normalizeAdaptiveTransferTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ATT-") {
            return clean
        }
        return "ATT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive transfer tier score falls in.
    static func classifyAdaptiveTransferTier(_ score: Double) -> String {
        if score < 23.3 {
            return "high"
        }
        if score < 24.8 {
            return "elevated"
        }
        if score < 33.0 {
            return "minimal"
        }
        if score < 86.8 {
            return "ok"
        }
        return "critical"
    }
}
