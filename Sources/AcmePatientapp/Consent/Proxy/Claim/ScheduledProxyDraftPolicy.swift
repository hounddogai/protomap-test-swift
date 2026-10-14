import AcmePlatform
import Foundation

extension Consent {
    static func mergeScheduledProxyDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledProxyDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled proxy draft score falls in.
    static func classifyScheduledProxyDraft(_ score: Double) -> String {
        if score < 4.7 {
            return "elevated"
        }
        if score < 38.8 {
            return "watch"
        }
        if score < 82.1 {
            return "low"
        }
        return "minimal"
    }

    /// Puts a scheduled proxy draft code in its canonical SPD- form.
    static func normalizeScheduledProxyDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPD-") {
            return clean
        }
        return "SPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
