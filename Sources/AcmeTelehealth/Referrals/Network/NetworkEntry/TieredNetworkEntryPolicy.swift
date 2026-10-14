import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a tiered network entry score falls in.
    static func classifyTieredNetworkEntry(_ score: Double) -> String {
        if score < 31.0 {
            return "ok"
        }
        if score < 44.9 {
            return "watch"
        }
        return "high"
    }

    /// Puts a tiered network entry code in its canonical TNE- form.
    static func normalizeTieredNetworkEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TNE-") {
            return clean
        }
        return "TNE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 5466.0, in order.
    static func tieredNetworkEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5466.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredNetworkEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-network-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
