import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackInventoryScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-inventory-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback inventory score code in its canonical FIS- form.
    static func normalizeFallbackInventoryScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FIS-") {
            return clean
        }
        return "FIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 23624.0, in order.
    static func fallbackInventoryScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23624.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func fallbackInventoryScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
