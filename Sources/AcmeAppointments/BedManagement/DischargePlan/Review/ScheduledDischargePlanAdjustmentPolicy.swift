import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledDischargePlanAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-discharge-plan-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled discharge plan adjustment code in its canonical SDPA- form.
    static func normalizeScheduledDischargePlanAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDPA-") {
            return clean
        }
        return "SDPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
