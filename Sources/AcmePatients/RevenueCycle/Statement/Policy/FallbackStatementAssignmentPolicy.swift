import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a fallback statement assignment code in its canonical FSA- form.
    static func normalizeFallbackStatementAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSA-") {
            return clean
        }
        return "FSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a fallback statement assignment score falls in.
    static func classifyFallbackStatementAssignment(_ score: Double) -> String {
        if score < 28.6 {
            return "ok"
        }
        if score < 68.2 {
            return "critical"
        }
        if score < 99.2 {
            return "minimal"
        }
        return "high"
    }

    static func fallbackStatementAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
