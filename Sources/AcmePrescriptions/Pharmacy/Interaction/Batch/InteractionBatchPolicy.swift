import AcmePlatform
import Foundation

extension Pharmacy {
    static func interactionBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a interaction batch code in its canonical IB- form.
    static func normalizeInteractionBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IB-") {
            return clean
        }
        return "IB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a interaction batch score falls in.
    static func classifyInteractionBatch(_ score: Double) -> String {
        if score < 10.0 {
            return "critical"
        }
        if score < 56.1 {
            return "minimal"
        }
        if score < 88.9 {
            return "high"
        }
        return "low"
    }
}
