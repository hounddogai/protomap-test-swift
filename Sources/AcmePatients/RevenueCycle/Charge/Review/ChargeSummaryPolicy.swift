import AcmePlatform
import Foundation

extension RevenueCycle {
    static func chargeSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a charge summary code in its canonical CS- form.
    static func normalizeChargeSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a charge summary score falls in.
    static func classifyChargeSummary(_ score: Double) -> String {
        if score < 59.4 {
            return "critical"
        }
        if score < 73.7 {
            return "minimal"
        }
        if score < 96.8 {
            return "ok"
        }
        return "watch"
    }
}
