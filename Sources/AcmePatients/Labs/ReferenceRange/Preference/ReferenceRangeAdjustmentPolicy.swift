import AcmePlatform
import Foundation

extension Labs {
    /// Puts a reference range adjustment code in its canonical RRA- form.
    static func normalizeReferenceRangeAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRA-") {
            return clean
        }
        return "RRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangeAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func referenceRangeAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
