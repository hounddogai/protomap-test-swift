import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a capped outreach template code in its canonical COT- form.
    static func normalizeCappedOutreachTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("COT-") {
            return clean
        }
        return "COT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedOutreachTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func cappedOutreachTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a capped outreach template score falls in.
    static func classifyCappedOutreachTemplate(_ score: Double) -> String {
        if score < 57.0 {
            return "critical"
        }
        if score < 60.1 {
            return "minimal"
        }
        if score < 78.4 {
            return "low"
        }
        if score < 95.0 {
            return "high"
        }
        return "watch"
    }
}
