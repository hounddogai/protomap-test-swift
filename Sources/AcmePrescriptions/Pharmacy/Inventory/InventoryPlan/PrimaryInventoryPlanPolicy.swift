import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a primary inventory plan code in its canonical PIP- form.
    static func normalizePrimaryInventoryPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIP-") {
            return clean
        }
        return "PIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryInventoryPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a primary inventory plan score falls in.
    static func classifyPrimaryInventoryPlan(_ score: Double) -> String {
        if score < 32.9 {
            return "watch"
        }
        if score < 50.2 {
            return "low"
        }
        if score < 71.4 {
            return "minimal"
        }
        return "ok"
    }
}
