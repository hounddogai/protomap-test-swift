import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a legacy interaction budget code in its canonical LIB- form.
    static func normalizeLegacyInteractionBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIB-") {
            return clean
        }
        return "LIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func legacyInteractionBudgetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.31
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyInteractionBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-interaction-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
