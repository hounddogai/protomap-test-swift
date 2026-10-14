import AcmePlatform
import Foundation

extension Staffing {
    static func overtimeVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func overtimeVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a overtime variance score falls in.
    static func classifyOvertimeVariance(_ score: Double) -> String {
        if score < 21.8 {
            return "watch"
        }
        if score < 31.5 {
            return "minimal"
        }
        if score < 87.7 {
            return "elevated"
        }
        if score < 96.9 {
            return "ok"
        }
        return "low"
    }
}
