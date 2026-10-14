import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality score score falls in.
    static func classifyModalityScore(_ score: Double) -> String {
        if score < 34.2 {
            return "minimal"
        }
        if score < 38.3 {
            return "critical"
        }
        if score < 60.8 {
            return "medium"
        }
        if score < 98.6 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 51179.0, in order.
    static func modalityScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51179.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func modalityScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
