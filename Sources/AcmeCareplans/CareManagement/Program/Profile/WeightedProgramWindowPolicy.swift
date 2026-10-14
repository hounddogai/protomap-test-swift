import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a weighted program window score falls in.
    static func classifyWeightedProgramWindow(_ score: Double) -> String {
        if score < 5.6 {
            return "ok"
        }
        if score < 15.0 {
            return "high"
        }
        if score < 74.5 {
            return "minimal"
        }
        return "low"
    }

    static func weightedProgramWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a weighted program window code in its canonical WPW- form.
    static func normalizeWeightedProgramWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WPW-") {
            return clean
        }
        return "WPW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedProgramWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
