import AcmePlatform
import Foundation

extension Staffing {
    static func regionalAcuityPlanClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalAcuityPlanClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-acuity-plan-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional acuity plan claim code in its canonical RAPC- form.
    static func normalizeRegionalAcuityPlanClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAPC-") {
            return clean
        }
        return "RAPC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalAcuityPlanClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
