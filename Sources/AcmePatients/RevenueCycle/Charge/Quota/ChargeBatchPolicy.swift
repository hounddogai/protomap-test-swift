import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a charge batch code in its canonical CB- form.
    static func normalizeChargeBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CB-") {
            return clean
        }
        return "CB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func chargeBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a charge batch score falls in.
    static func classifyChargeBatch(_ score: Double) -> String {
        if score < 57.0 {
            return "low"
        }
        if score < 57.2 {
            return "ok"
        }
        return "medium"
    }
}
