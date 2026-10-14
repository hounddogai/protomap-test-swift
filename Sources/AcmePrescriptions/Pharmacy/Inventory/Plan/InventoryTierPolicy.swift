import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func inventoryTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a inventory tier score falls in.
    static func classifyInventoryTier(_ score: Double) -> String {
        if score < 2.3 {
            return "elevated"
        }
        if score < 66.3 {
            return "high"
        }
        if score < 68.5 {
            return "minimal"
        }
        if score < 94.3 {
            return "low"
        }
        return "ok"
    }

    /// Puts a inventory tier code in its canonical IT- form.
    static func normalizeInventoryTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IT-") {
            return clean
        }
        return "IT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
