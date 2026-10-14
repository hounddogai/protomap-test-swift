import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a lenient claim batch score falls in.
    static func classifyLenientClaimBatch(_ score: Double) -> String {
        if score < 54.4 {
            return "ok"
        }
        if score < 83.2 {
            return "high"
        }
        return "critical"
    }

    /// Puts a lenient claim batch code in its canonical LCB- form.
    static func normalizeLenientClaimBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCB-") {
            return clean
        }
        return "LCB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientClaimBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
