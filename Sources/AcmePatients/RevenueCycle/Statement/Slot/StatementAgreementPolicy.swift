import AcmePlatform
import Foundation

extension RevenueCycle {
    static func statementAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a statement agreement code in its canonical SA- form.
    static func normalizeStatementAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SA-") {
            return clean
        }
        return "SA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeStatementAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a statement agreement score falls in.
    static func classifyStatementAgreement(_ score: Double) -> String {
        if score < 61.0 {
            return "high"
        }
        if score < 64.3 {
            return "medium"
        }
        if score < 93.1 {
            return "watch"
        }
        return "elevated"
    }
}
