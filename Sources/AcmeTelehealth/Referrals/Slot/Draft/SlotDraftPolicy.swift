import AcmePlatform
import Foundation

extension Referrals {
    static func slotDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a slot draft code in its canonical SD- form.
    static func normalizeSlotDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SD-") {
            return clean
        }
        return "SD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a slot draft score falls in.
    static func classifySlotDraft(_ score: Double) -> String {
        if score < 81.3 {
            return "watch"
        }
        if score < 88.9 {
            return "elevated"
        }
        return "low"
    }
}
