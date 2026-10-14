import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a inventory agreement code in its canonical IA- form.
    static func normalizeInventoryAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IA-") {
            return clean
        }
        return "IA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a inventory agreement score falls in.
    static func classifyInventoryAgreement(_ score: Double) -> String {
        if score < 4.1 {
            return "medium"
        }
        if score < 57.1 {
            return "critical"
        }
        if score < 61.7 {
            return "elevated"
        }
        if score < 85.2 {
            return "high"
        }
        return "ok"
    }
}
