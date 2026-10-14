import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 80126.0, in order.
    static func proxyThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 80126.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a proxy threshold code in its canonical PT- form.
    static func normalizeProxyThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PT-") {
            return clean
        }
        return "PT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
