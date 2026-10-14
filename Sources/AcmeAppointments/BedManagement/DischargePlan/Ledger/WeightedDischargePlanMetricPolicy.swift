import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a weighted discharge plan metric score falls in.
    static func classifyWeightedDischargePlanMetric(_ score: Double) -> String {
        if score < 7.4 {
            return "watch"
        }
        if score < 27.9 {
            return "low"
        }
        if score < 57.4 {
            return "ok"
        }
        if score < 63.6 {
            return "medium"
        }
        return "critical"
    }

    /// Puts a weighted discharge plan metric code in its canonical WDPM- form.
    static func normalizeWeightedDischargePlanMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WDPM-") {
            return clean
        }
        return "WDPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedDischargePlanMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-discharge-plan-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 40740.0, in order.
    static func weightedDischargePlanMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40740.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
