import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 83162.0, in order.
    static func dischargePlanNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83162.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan notice score falls in.
    static func classifyDischargePlanNotice(_ score: Double) -> String {
        if score < 1.3 {
            return "ok"
        }
        if score < 46.7 {
            return "high"
        }
        if score < 100.0 {
            return "medium"
        }
        return "minimal"
    }

    static func dischargePlanNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.55
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
