import AcmePlatform
import Foundation

extension Labs {
    /// Puts a adaptive reference range assignment code in its canonical ARRA- form.
    static func normalizeAdaptiveReferenceRangeAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARRA-") {
            return clean
        }
        return "ARRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveReferenceRangeAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveReferenceRangeAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-reference-range-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
