import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictTaskVariance() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-task-variance")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a strict task variance code in its canonical STV- form.
    static func normalizeStrictTaskVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("STV-") {
            return clean
        }
        return "STV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 72039.0, in order.
    static func strictTaskVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 72039.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
