import AcmePlatform
import Foundation

extension Staffing {
    static func cappedOvertimeMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func cappedOvertimeMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a capped overtime mapping code in its canonical COM- form.
    static func normalizeCappedOvertimeMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("COM-") {
            return clean
        }
        return "COM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped overtime mapping score falls in.
    static func classifyCappedOvertimeMapping(_ score: Double) -> String {
        if score < 22.2 {
            return "ok"
        }
        if score < 92.0 {
            return "low"
        }
        return "critical"
    }
}
