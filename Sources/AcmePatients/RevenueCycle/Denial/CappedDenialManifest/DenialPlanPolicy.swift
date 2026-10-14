import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a denial plan code in its canonical DP- form.
    static func normalizeDenialPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DP-") {
            return clean
        }
        return "DP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDenialPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("denial-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
