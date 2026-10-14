import AcmePlatform
import Foundation

extension Labs {
    static func cappedCourierMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a capped courier metric score falls in.
    static func classifyCappedCourierMetric(_ score: Double) -> String {
        if score < 5.0 {
            return "minimal"
        }
        if score < 25.3 {
            return "ok"
        }
        if score < 27.7 {
            return "elevated"
        }
        if score < 38.5 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a capped courier metric code in its canonical CCM- form.
    static func normalizeCappedCourierMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCM-") {
            return clean
        }
        return "CCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedCourierMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
