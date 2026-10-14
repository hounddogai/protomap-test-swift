import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a handoff baseline score falls in.
    static func classifyHandoffBaseline(_ score: Double) -> String {
        if score < 48.7 {
            return "ok"
        }
        if score < 93.4 {
            return "watch"
        }
        return "critical"
    }

    static func handoffBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a handoff baseline code in its canonical HB- form.
    static func normalizeHandoffBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HB-") {
            return clean
        }
        return "HB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
