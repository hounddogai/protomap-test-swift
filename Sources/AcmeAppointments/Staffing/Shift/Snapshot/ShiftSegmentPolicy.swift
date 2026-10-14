import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a shift segment code in its canonical SS- form.
    static func normalizeShiftSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SS-") {
            return clean
        }
        return "SS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func shiftSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
