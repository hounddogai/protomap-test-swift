import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualWitnessRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-witness-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 91573.0, in order.
    static func manualWitnessRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91573.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a manual witness rollup code in its canonical MWR- form.
    static func normalizeManualWitnessRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MWR-") {
            return clean
        }
        return "MWR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
