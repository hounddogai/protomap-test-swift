import AcmePlatform
import Foundation

extension BedManagement {
    static func rollingDischargePlanScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a rolling discharge plan schedule score falls in.
    static func classifyRollingDischargePlanSchedule(_ score: Double) -> String {
        if score < 57.6 {
            return "medium"
        }
        if score < 78.4 {
            return "watch"
        }
        return "high"
    }

    /// Puts a rolling discharge plan schedule code in its canonical RDPS- form.
    static func normalizeRollingDischargePlanScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDPS-") {
            return clean
        }
        return "RDPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
