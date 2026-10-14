import AcmePlatform
import Foundation

extension Consent {
    /// Puts a batched revocation baseline code in its canonical BRB- form.
    static func normalizeBatchedRevocationBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRB-") {
            return clean
        }
        return "BRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedRevocationBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedRevocationBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-revocation-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
