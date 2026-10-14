import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 43808.0, in order.
    static func rollingDisclosureAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43808.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingDisclosureAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-disclosure-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling disclosure agreement code in its canonical RDA- form.
    static func normalizeRollingDisclosureAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RDA-") {
            return clean
        }
        return "RDA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
