import AcmePlatform
import Foundation

extension Labs {
    static func cappedResultRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a capped result rule code in its canonical CRR- form.
    static func normalizeCappedResultRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CRR-") {
            return clean
        }
        return "CRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedResultRuleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a capped result rule score falls in.
    static func classifyCappedResultRule(_ score: Double) -> String {
        if score < 17.1 {
            return "critical"
        }
        if score < 46.4 {
            return "ok"
        }
        if score < 55.3 {
            return "low"
        }
        if score < 63.9 {
            return "high"
        }
        return "medium"
    }
}
