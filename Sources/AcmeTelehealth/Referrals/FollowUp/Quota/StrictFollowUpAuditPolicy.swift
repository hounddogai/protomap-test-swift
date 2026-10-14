import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a strict follow up audit code in its canonical SFUA- form.
    static func normalizeStrictFollowUpAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFUA-") {
            return clean
        }
        return "SFUA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict follow up audit score falls in.
    static func classifyStrictFollowUpAudit(_ score: Double) -> String {
        if score < 12.2 {
            return "minimal"
        }
        if score < 13.4 {
            return "ok"
        }
        return "high"
    }

    static func strictFollowUpAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeStrictFollowUpAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
