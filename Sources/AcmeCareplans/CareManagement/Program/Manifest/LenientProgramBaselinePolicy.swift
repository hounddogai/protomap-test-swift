import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a lenient program baseline code in its canonical LPB- form.
    static func normalizeLenientProgramBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LPB-") {
            return clean
        }
        return "LPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientProgramBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-program-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 57822.0, in order.
    static func lenientProgramBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57822.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
