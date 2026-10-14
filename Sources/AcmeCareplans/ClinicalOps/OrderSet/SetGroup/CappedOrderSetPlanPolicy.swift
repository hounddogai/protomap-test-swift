import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a capped order set plan code in its canonical COSP- form.
    static func normalizeCappedOrderSetPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("COSP-") {
            return clean
        }
        return "COSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedOrderSetPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a capped order set plan score falls in.
    static func classifyCappedOrderSetPlan(_ score: Double) -> String {
        if score < 30.6 {
            return "low"
        }
        if score < 55.7 {
            return "medium"
        }
        return "watch"
    }

    static func cappedOrderSetPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
