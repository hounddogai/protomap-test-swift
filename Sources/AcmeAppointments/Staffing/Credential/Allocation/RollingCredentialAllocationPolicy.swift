import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a rolling credential allocation code in its canonical RCA- form.
    static func normalizeRollingCredentialAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCA-") {
            return clean
        }
        return "RCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling credential allocation score falls in.
    static func classifyRollingCredentialAllocation(_ score: Double) -> String {
        if score < 18.0 {
            return "elevated"
        }
        if score < 91.3 {
            return "high"
        }
        return "low"
    }

    static func rollingCredentialAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
