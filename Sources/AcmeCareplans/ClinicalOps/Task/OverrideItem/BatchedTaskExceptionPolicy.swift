import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a batched task exception code in its canonical BTE- form.
    static func normalizeBatchedTaskExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BTE-") {
            return clean
        }
        return "BTE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeBatchedTaskExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedTaskException() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-task-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 20236.0, in order.
    static func batchedTaskExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20236.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
