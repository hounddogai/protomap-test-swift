import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a substitution agreement code in its canonical SA- form.
    static func normalizeSubstitutionAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SA-") {
            return clean
        }
        return "SA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a substitution agreement score falls in.
    static func classifySubstitutionAgreement(_ score: Double) -> String {
        if score < 1.4 {
            return "low"
        }
        if score < 22.7 {
            return "elevated"
        }
        if score < 27.0 {
            return "medium"
        }
        if score < 73.9 {
            return "watch"
        }
        return "critical"
    }

    static func substitutionAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func substitutionAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
