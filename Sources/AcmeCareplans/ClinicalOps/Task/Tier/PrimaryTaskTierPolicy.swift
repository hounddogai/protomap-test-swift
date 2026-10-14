import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a primary task tier code in its canonical PTT- form.
    static func normalizePrimaryTaskTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PTT-") {
            return clean
        }
        return "PTT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryTaskTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-task-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryTaskTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
