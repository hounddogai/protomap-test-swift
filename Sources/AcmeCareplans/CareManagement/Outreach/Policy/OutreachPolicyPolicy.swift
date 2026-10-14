import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 95776.0, in order.
    static func outreachPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95776.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOutreachPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("outreach-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a outreach policy code in its canonical OP- form.
    static func normalizeOutreachPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OP-") {
            return clean
        }
        return "OP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
