import AcmePlatform
import Foundation

extension Consent {
    static func proxySlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func proxySlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a proxy slot code in its canonical PS- form.
    static func normalizeProxySlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PS-") {
            return clean
        }
        return "PS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a proxy slot score falls in.
    static func classifyProxySlot(_ score: Double) -> String {
        if score < 6.7 {
            return "high"
        }
        if score < 60.2 {
            return "low"
        }
        return "critical"
    }
}
