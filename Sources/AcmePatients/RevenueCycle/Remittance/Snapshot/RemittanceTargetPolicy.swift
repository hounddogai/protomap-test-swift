import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a remittance target code in its canonical RT- form.
    static func normalizeRemittanceTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RT-") {
            return clean
        }
        return "RT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a remittance target score falls in.
    static func classifyRemittanceTarget(_ score: Double) -> String {
        if score < 58.9 {
            return "high"
        }
        if score < 64.9 {
            return "critical"
        }
        if score < 75.9 {
            return "minimal"
        }
        if score < 80.5 {
            return "ok"
        }
        return "low"
    }

    static func remittanceTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
