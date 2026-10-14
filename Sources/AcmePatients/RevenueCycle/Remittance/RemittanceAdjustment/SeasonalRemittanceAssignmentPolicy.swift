import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a seasonal remittance assignment code in its canonical SRA- form.
    static func normalizeSeasonalRemittanceAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRA-") {
            return clean
        }
        return "SRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalRemittanceAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func seasonalRemittanceAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalRemittanceAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-remittance-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
