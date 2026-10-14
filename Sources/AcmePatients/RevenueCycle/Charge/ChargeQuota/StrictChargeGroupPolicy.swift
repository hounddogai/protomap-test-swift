import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a strict charge group code in its canonical SCG- form.
    static func normalizeStrictChargeGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCG-") {
            return clean
        }
        return "SCG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict charge group score falls in.
    static func classifyStrictChargeGroup(_ score: Double) -> String {
        if score < 4.2 {
            return "elevated"
        }
        if score < 21.4 {
            return "minimal"
        }
        if score < 40.7 {
            return "medium"
        }
        if score < 69.4 {
            return "critical"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictChargeGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-charge-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 74171.0, in order.
    static func strictChargeGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74171.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
