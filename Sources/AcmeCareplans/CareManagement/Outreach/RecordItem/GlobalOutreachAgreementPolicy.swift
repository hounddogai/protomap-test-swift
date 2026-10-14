import AcmePlatform
import Foundation

extension CareManagement {
    static func globalOutreachAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeGlobalOutreachAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global outreach agreement code in its canonical GOA- form.
    static func normalizeGlobalOutreachAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GOA-") {
            return clean
        }
        return "GOA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global outreach agreement score falls in.
    static func classifyGlobalOutreachAgreement(_ score: Double) -> String {
        if score < 15.3 {
            return "elevated"
        }
        if score < 22.0 {
            return "critical"
        }
        if score < 31.2 {
            return "watch"
        }
        return "minimal"
    }
}
