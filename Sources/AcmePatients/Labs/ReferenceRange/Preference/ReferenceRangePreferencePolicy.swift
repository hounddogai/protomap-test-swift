import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 49105.0, in order.
    static func referenceRangePreferenceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 49105.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangePreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func referenceRangePreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func referenceRangePreferenceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
