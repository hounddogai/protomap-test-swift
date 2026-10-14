import AcmePlatform
import Foundation

extension Staffing {
    static func acuityPlanSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func acuityPlanSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a acuity plan slot code in its canonical APS- form.
    static func normalizeAcuityPlanSlotCode(_ code: String) -> String {
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
