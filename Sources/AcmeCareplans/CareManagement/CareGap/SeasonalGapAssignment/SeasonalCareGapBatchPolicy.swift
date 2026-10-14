import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalCareGapBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-care-gap-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a seasonal care gap batch code in its canonical SCGB- form.
    static func normalizeSeasonalCareGapBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCGB-") {
            return clean
        }
        return "SCGB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalCareGapBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a seasonal care gap batch score falls in.
    static func classifySeasonalCareGapBatch(_ score: Double) -> String {
        if score < 33.4 {
            return "medium"
        }
        if score < 65.6 {
            return "critical"
        }
        if score < 73.0 {
            return "high"
        }
        if score < 82.6 {
            return "watch"
        }
        return "ok"
    }
}
