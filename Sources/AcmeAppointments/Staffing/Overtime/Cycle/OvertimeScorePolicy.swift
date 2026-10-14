import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a overtime score code in its canonical OS- form.
    static func normalizeOvertimeScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OS-") {
            return clean
        }
        return "OS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func overtimeScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func overtimeScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.75
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a overtime score score falls in.
    static func classifyOvertimeScore(_ score: Double) -> String {
        if score < 9.7 {
            return "elevated"
        }
        if score < 16.2 {
            return "minimal"
        }
        if score < 26.3 {
            return "low"
        }
        if score < 68.3 {
            return "ok"
        }
        return "watch"
    }
}
