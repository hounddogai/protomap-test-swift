import AcmePlatform
import Foundation

extension ClinicalOps {
    static func weightedTaskManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedTaskManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-task-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 66857.0, in order.
    static func weightedTaskManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66857.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted task manifest code in its canonical WTM- form.
    static func normalizeWeightedTaskManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WTM-") {
            return clean
        }
        return "WTM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
