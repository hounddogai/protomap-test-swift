import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a tiered authorization bundle code in its canonical TAB- form.
    static func normalizeTieredAuthorizationBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TAB-") {
            return clean
        }
        return "TAB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredAuthorizationBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-authorization-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered authorization bundle score falls in.
    static func classifyTieredAuthorizationBundle(_ score: Double) -> String {
        if score < 76.8 {
            return "minimal"
        }
        if score < 80.5 {
            return "low"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 6988.0, in order.
    static func tieredAuthorizationBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6988.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
