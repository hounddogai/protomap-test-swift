import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalHandoffMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-handoff-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 61182.0, in order.
    static func seasonalHandoffMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61182.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func seasonalHandoffMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a seasonal handoff milestone code in its canonical SHM- form.
    static func normalizeSeasonalHandoffMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SHM-") {
            return clean
        }
        return "SHM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
