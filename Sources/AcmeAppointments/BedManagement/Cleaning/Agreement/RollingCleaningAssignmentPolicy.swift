import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingCleaningAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-cleaning-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling cleaning assignment code in its canonical RCA- form.
    static func normalizeRollingCleaningAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCA-") {
            return clean
        }
        return "RCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingCleaningAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
