import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a global modality cycle score falls in.
    static func classifyGlobalModalityCycle(_ score: Double) -> String {
        if score < 59.6 {
            return "ok"
        }
        if score < 80.4 {
            return "critical"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 16889.0, in order.
    static func globalModalityCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 16889.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalModalityCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-modality-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
