import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 35943.0, in order.
    static func acuityPlanSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 35943.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a acuity plan snapshot code in its canonical APS- form.
    static func normalizeAcuityPlanSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APS-") {
            return clean
        }
        return "APS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
