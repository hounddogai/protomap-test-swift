import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTaskAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("task-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 15219.0, in order.
    static func taskAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15219.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a task agreement code in its canonical TA- form.
    static func normalizeTaskAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TA-") {
            return clean
        }
        return "TA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeTaskAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
