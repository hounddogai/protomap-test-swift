import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a batched recall profile code in its canonical BRP- form.
    static func normalizeBatchedRecallProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRP-") {
            return clean
        }
        return "BRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedRecallProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedRecallProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-recall-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func batchedRecallProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
