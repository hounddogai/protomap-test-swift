import AcmePlatform
import Foundation

extension BedManagement {
    static func primaryTransferAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryTransferAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-transfer-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary transfer assignment code in its canonical PTA- form.
    static func normalizePrimaryTransferAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PTA-") {
            return clean
        }
        return "PTA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryTransferAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
