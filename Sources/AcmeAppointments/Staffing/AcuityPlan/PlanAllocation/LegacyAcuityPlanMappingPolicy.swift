import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAcuityPlanMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-acuity-plan-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy acuity plan mapping score falls in.
    static func classifyLegacyAcuityPlanMapping(_ score: Double) -> String {
        if score < 16.4 {
            return "minimal"
        }
        if score < 61.0 {
            return "watch"
        }
        if score < 62.9 {
            return "elevated"
        }
        return "medium"
    }
}
