import AcmePlatform
import Foundation

extension RevenueCycle {
    static func cappedStatementForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a capped statement forecast code in its canonical CSF- form.
    static func normalizeCappedStatementForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CSF-") {
            return clean
        }
        return "CSF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped statement forecast score falls in.
    static func classifyCappedStatementForecast(_ score: Double) -> String {
        if score < 50.6 {
            return "elevated"
        }
        if score < 51.1 {
            return "high"
        }
        if score < 86.9 {
            return "low"
        }
        if score < 98.3 {
            return "watch"
        }
        return "ok"
    }
}
