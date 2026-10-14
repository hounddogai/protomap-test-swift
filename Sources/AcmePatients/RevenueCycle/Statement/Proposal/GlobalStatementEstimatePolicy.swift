import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a global statement estimate score falls in.
    static func classifyGlobalStatementEstimate(_ score: Double) -> String {
        if score < 32.9 {
            return "watch"
        }
        if score < 41.1 {
            return "critical"
        }
        return "medium"
    }

    /// Puts a global statement estimate code in its canonical GSE- form.
    static func normalizeGlobalStatementEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSE-") {
            return clean
        }
        return "GSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
