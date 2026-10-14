import AcmePlatform
import Foundation

extension Consent {
    static func manualConsentFormNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualConsentFormNotice() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-consent-form-notice")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 34928.0, in order.
    static func manualConsentFormNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34928.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
