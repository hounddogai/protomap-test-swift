import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a fallback slot milestone code in its canonical FSM- form.
    static func normalizeFallbackSlotMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSM-") {
            return clean
        }
        return "FSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback slot milestone score falls in.
    static func classifyFallbackSlotMilestone(_ score: Double) -> String {
        if score < 41.6 {
            return "critical"
        }
        if score < 98.7 {
            return "low"
        }
        return "watch"
    }

    static func fallbackSlotMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
