import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalCareProtocolQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-care-protocol-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalCareProtocolQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a regional care protocol quota score falls in.
    static func classifyRegionalCareProtocolQuota(_ score: Double) -> String {
        if score < 13.5 {
            return "ok"
        }
        if score < 32.4 {
            return "low"
        }
        if score < 80.3 {
            return "medium"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 61805.0, in order.
    static func regionalCareProtocolQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61805.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
