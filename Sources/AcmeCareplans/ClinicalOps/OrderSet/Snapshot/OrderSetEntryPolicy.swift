import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 58430.0, in order.
    static func orderSetEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58430.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a order set entry code in its canonical OSE- form.
    static func normalizeOrderSetEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSE-") {
            return clean
        }
        return "OSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
