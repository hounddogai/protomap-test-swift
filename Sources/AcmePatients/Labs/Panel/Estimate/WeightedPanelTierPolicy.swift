import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 1316.0, in order.
    static func weightedPanelTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1316.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted panel tier code in its canonical WPT- form.
    static func normalizeWeightedPanelTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WPT-") {
            return clean
        }
        return "WPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedPanelTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-panel-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a weighted panel tier score falls in.
    static func classifyWeightedPanelTier(_ score: Double) -> String {
        if score < 12.5 {
            return "critical"
        }
        if score < 17.1 {
            return "medium"
        }
        if score < 27.5 {
            return "elevated"
        }
        if score < 28.8 {
            return "high"
        }
        return "ok"
    }
}
