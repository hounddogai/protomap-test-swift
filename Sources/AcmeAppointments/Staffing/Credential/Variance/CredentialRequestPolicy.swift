import AcmePlatform
import Foundation

extension Staffing {
    static func credentialRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a credential request score falls in.
    static func classifyCredentialRequest(_ score: Double) -> String {
        if score < 50.4 {
            return "low"
        }
        if score < 52.6 {
            return "minimal"
        }
        if score < 60.9 {
            return "medium"
        }
        if score < 99.6 {
            return "watch"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 73596.0, in order.
    static func credentialRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73596.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
