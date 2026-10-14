import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalDischargePlanEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-discharge-plan-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global discharge plan estimate score falls in.
    static func classifyGlobalDischargePlanEstimate(_ score: Double) -> String {
        if score < 23.5 {
            return "ok"
        }
        if score < 69.0 {
            return "elevated"
        }
        if score < 98.7 {
            return "watch"
        }
        return "high"
    }

    /// Puts a global discharge plan estimate code in its canonical GDPE- form.
    static func normalizeGlobalDischargePlanEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDPE-") {
            return clean
        }
        return "GDPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalDischargePlanEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.11
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
