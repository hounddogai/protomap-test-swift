import AcmePlatform
import Foundation

extension Imaging {
    static func globalPriorityAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a global priority agreement score falls in.
    static func classifyGlobalPriorityAgreement(_ score: Double) -> String {
        if score < 11.1 {
            return "medium"
        }
        if score < 36.1 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a global priority agreement code in its canonical GPA- form.
    static func normalizeGlobalPriorityAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GPA-") {
            return clean
        }
        return "GPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalPriorityAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
