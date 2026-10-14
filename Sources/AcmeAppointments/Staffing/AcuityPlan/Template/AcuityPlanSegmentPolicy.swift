import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a acuity plan segment code in its canonical APS- form.
    static func normalizeAcuityPlanSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APS-") {
            return clean
        }
        return "APS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 98049.0, in order.
    static func acuityPlanSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98049.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
