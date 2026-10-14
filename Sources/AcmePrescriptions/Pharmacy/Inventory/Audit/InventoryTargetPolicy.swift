import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a inventory target score falls in.
    static func classifyInventoryTarget(_ score: Double) -> String {
        if score < 49.9 {
            return "high"
        }
        if score < 74.1 {
            return "ok"
        }
        if score < 84.2 {
            return "minimal"
        }
        if score < 99.4 {
            return "elevated"
        }
        return "watch"
    }

    /// Puts a inventory target code in its canonical IT- form.
    static func normalizeInventoryTargetCode(_ code: String) -> String {
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
