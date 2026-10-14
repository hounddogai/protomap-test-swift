import AcmePlatform
import Foundation

extension BedManagement {
    static func cappedDischargePlanThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedDischargePlanThreshold() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-discharge-plan-threshold")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped discharge plan threshold code in its canonical CDPT- form.
    static func normalizeCappedDischargePlanThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CDPT-") {
            return clean
        }
        return "CDPT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
