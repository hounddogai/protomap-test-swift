import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a weighted substitution digest code in its canonical WSD- form.
    static func normalizeWeightedSubstitutionDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WSD-") {
            return clean
        }
        return "WSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 34475.0, in order.
    static func weightedSubstitutionDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 34475.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedSubstitutionDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-substitution-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
