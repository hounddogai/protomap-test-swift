import AcmePlatform
import Foundation

extension ClinicalOps {
    static func seasonalTaskEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalTaskEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-task-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func seasonalTaskEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Puts a seasonal task estimate code in its canonical STE- form.
    static func normalizeSeasonalTaskEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("STE-") {
            return clean
        }
        return "STE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
