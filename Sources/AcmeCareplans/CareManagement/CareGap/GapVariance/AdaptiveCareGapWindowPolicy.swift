import AcmePlatform
import Foundation

extension CareManagement {
    static func adaptiveCareGapWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a adaptive care gap window code in its canonical ACGW- form.
    static func normalizeAdaptiveCareGapWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACGW-") {
            return clean
        }
        return "ACGW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveCareGapWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-care-gap-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
