import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a tiered priority target score falls in.
    static func classifyTieredPriorityTarget(_ score: Double) -> String {
        if score < 30.1 {
            return "watch"
        }
        if score < 34.0 {
            return "low"
        }
        if score < 37.0 {
            return "ok"
        }
        if score < 62.9 {
            return "minimal"
        }
        return "medium"
    }

    /// Puts a tiered priority target code in its canonical TPT- form.
    static func normalizeTieredPriorityTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TPT-") {
            return clean
        }
        return "TPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredPriorityTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
